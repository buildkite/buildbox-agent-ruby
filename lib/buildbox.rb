#!/usr/bin/env ruby

require 'rubygems'

require 'hashie/dash'
require 'pathname'
require 'json'

module UTF8
  # Replace or delete invalid UTF-8 characters from text, which is assumed
  # to be in UTF-8.
  #
  # The text is expected to come from external to Integrity sources such as
  # commit messages or build output.
  #
  # On ruby 1.9, invalid UTF-8 characters are replaced with question marks.
  # On ruby 1.8, if iconv extension is present, invalid UTF-8 characters
  # are removed.
  # On ruby 1.8, if iconv extension is not present, the string is unmodified.
  def self.clean(text)
    # http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
    # http://stackoverflow.com/questions/9126782/how-to-change-deprecated-iconv-to-stringencode-for-invalid-utf8-correction
    if text.respond_to?(:encoding)
      # ruby 1.9
      text = text.force_encoding('utf-8').encode(intermediate_encoding, :invalid => :replace, :replace => '?').encode('utf-8')
    else
      # ruby 1.8
      # As no encoding checks are done, any string will be accepted.
      # But delete invalid utf-8 characters anyway for consistency with 1.9.
      iconv, iconv_fallback = clean_utf8_iconv
      if iconv
        begin
          output = iconv.iconv(text)
        rescue Iconv::IllegalSequence
          output = iconv_fallback.iconv(text)
        end
      end
    end
    text
  end

  # Apparently utf-16 is not available everywhere, in particular not on travis.
  # Try to find a usable encoding.
  def self.intermediate_encoding
    map = {}
    Encoding.list.each do |encoding|
      map[encoding.name.downcase] = true
    end
    %w(utf-16 utf-16be utf-16le utf-7 utf-32 utf-32le utf-32be).each do |candidate|
      if map[candidate]
        return candidate
      end
    end
    raise CannotFindEncoding, 'Cannot find an intermediate encoding for conversion to UTF-8'
  end

  def self.clean_utf8_iconv
    unless @iconv_loaded
      begin
        require 'iconv'
      rescue LoadError
        @iconv = nil
      else
        @iconv = Iconv.new('utf-8//translit//ignore', 'utf-8')
        # On some systems (Linux appears to be vulnerable, FreeBSD not)
        # iconv chokes on invalid utf-8 with //translit//ignore.
        @iconv_fallback = Iconv.new('utf-8//ignore', 'utf-8')
      end
      @iconv_loaded = true
    end
    [@iconv, @iconv_fallback]
  end
end

class Configuration < Hashie::Dash
  property :worker_access_tokens, :default => []
  property :api_endpoint,         :default => "http://api.buildbox.dev/v1"

  def update(attributes)
    attributes.each_pair { |key, value| self[key] = value }
    save
  end

  def save
    File.open(path, 'w+') { |file| file.write(pretty_json) }
  end

  def reload
    if path.exist?
      read_and_load
    else
      save && read_and_load
    end
  end

  private

  def pretty_json
    JSON.pretty_generate(self)
  end

  def read_and_load
    merge! JSON.parse(path.read)
  end

  def path
    Buildbox.root_path.join("configuration.json")
  end
end

module Buildbox
  def self.config
    @config ||= Configuration.new.tap(&:reload)
  end

  def self.root_path
    path = Pathname.new File.join(ENV['HOME'], ".buildbox")
    path.mkpath unless path.exist?

    Pathname.new(path)
  end
end

require 'faraday'
require 'faraday_middleware'
require 'hashie/mash'

module API
  class Client
    def initialize(config = Buildbox.config)
      @config = config
    end

    def worker(access_token: access_token, hostname: hostname)
      put("workers/#{access_token}", :hostname => hostname)
    end

    def scheduled_builds(project)
      get(project.scheduled_builds_url)
    end

    def update_build(build)
      put(build.url, :output => build.output, :exit_status => build.exit_status)
    end

    private

    def connection
      @connection ||= Faraday.new(:url => @config.api_endpoint) do |faraday|
        faraday.request  :json

        faraday.response :logger
        faraday.response :mashify

        # json needs to come after mashify as it needs to run before the mashify
        # middleware.
        faraday.response :json

        faraday.adapter Faraday.default_adapter
      end
    end

    def post(path, body = {})
      connection.post(path) do |request|
        request.body = body
      end.body
    end

    def put(path, body = {})
      connection.put(path) do |request|
        request.body = body
      end.body
    end

    def get(path)
      connection.get(path).body
    end
  end
end

class Environment
  def initialize(environment)
    @environment = environment
  end

  def to_s
    @environment.to_a.map do |key, value|
      %{#{key}=#{value.inspect}}
    end.join(" ")
  end
end

class Script
  def initialize(build)
    @build = build
  end

  def name
    "#{@build.project.team.name}-#{@build.project.name}-#{@build.number}"
  end

  def path
    Buildbox.root_path.join(name)
  end

  def save
    File.open(path, 'w+') { |file| file.write(normalized_script) }
  end

  def delete
    File.delete(path)
  end

  private

  def normalized_script
    # normalize the line endings
    @build.script.gsub(/\r\n?/, "\n")
  end
end

require 'pty'

class Command
  def self.run(command, options = {}, &block)
    new(command, options).run(&block)
  end

  def initialize(command, options = {})
    @command       = command
    @path          = options[:path] || "."
    @read_interval = options[:read_interval] || 5
  end

  def run(&block)
    output = ""
    read_io, write_io, pid = nil

    # spawn the process in a pseudo terminal so colors out outputted
    read_io, write_io, pid = PTY.spawn("cd #{expanded_path} && #{@command}")

    # we don't need to write to the spawned io
    write_io.close

    loop do
      fds, = IO.select([read_io], nil, nil, read_interval)
      if fds
        # should have some data to read
        begin
          chunk         = read_io.read_nonblock(10240)
          cleaned_chunk = UTF8.clean(chunk)

          output << chunk
          yield cleaned_chunk if block_given?
        rescue Errno::EAGAIN, Errno::EWOULDBLOCK
          # do select again
        rescue EOFError, Errno::EIO # EOFError from OSX, EIO is raised by ubuntu
          break
        end
      end
      # if fds are empty, timeout expired - run another iteration
    end

    # we're done reading, yay!
    read_io.close

    # just wait until its finally finished closing
    Process.waitpid(pid)

    # the final result!
    [ output.chomp, $?.exitstatus ]
  end

  private

  def expanded_path
    File.expand_path(@path)
  end

  def read_interval
    @read_interval
  end
end

require 'celluloid'

class Builder
  include Celluloid
  include Celluloid::Logger

  attr_reader :build, :output

  def initialize(build)
    @build = build
  end

  def start
    info "Starting to build #{script.path} starting..."

    script.save

    build.output = ""
    output, exit_status = Command.run(command) { |chunk| build.output << chunk }

    build.output      = output
    build.exit_status = exit_status

    script.delete

    info "#{script.path} finished"
  end

  private

  def command
    %{chmod +x #{script.path} && #{environment} exec #{script.path}}
  end

  def script
    @script ||= Script.new(@build)
  end

  def environment
    @environment ||= Environment.new(@build.env)
  end
end

class Monitor
  include Celluloid

  def initialize(build, api)
    @build = build
    @api   = api
  end

  def monitor
    loop do
      @api.update_build(@build) if build_started?

      if build_finished?
        break
      else
        sleep 1
      end
    end
  end

  private

  def build_started?
    @build.output != nil
  end

  def build_finished?
    @build.exit_status != nil
  end
end

class Server
  def start
    loop do
      access_tokens.each do |access_token|
        api.worker(:access_token => access_token, :hostname => `hostname`.chomp).projects.each do |project|
          running_builds = api.scheduled_builds(project).map do |build|
            Monitor.new(build, api).async.monitor
            Builder.new(build).future(:start)
          end

          # wait for all the running builds to finish
          running_builds.map(&:value)

          sleep 5
        end
      end
    end
  end

  private

  def api
    @api ||= API::Client.new
  end

  def access_tokens
    Buildbox.config.worker_access_tokens
  end
end

Buildbox.config.update(:worker_access_tokens=> [ "5f6e1a888c8ef547f6b3" ])

server = Server.new
server.start
