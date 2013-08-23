#!/usr/bin/env ruby

require 'rubygems'

require 'hashie/dash'
require 'pathname'
require 'json'

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

    build.output = `#{command}`
    build.exit_status = $?.to_i

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
