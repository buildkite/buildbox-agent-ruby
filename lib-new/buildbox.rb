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

class Environment < Hash
  def initialize(environment)
    @environment = environment
    self['FOO'] = "BAR"
    self['TEST'] = "this is a test"
  end

  def to_s
    to_a.map do |key, value|
      %{#{key}=#{value.inspect}}
    end.join(" ")
  end
end

require 'celluloid'
require 'tempfile'

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
    File.open(path, 'w+') { |file| file.write(@build.script) }
  end

  def delete
    File.delete(path)
  end
end

class Builder
  include Celluloid

  def initialize(build)
    @build = build
  end

  def start
    script.save
    puts `#{command}`
    script.delete
  end

  private

  def command
    %{#{environment} sh #{script.path}}
  end

  def script
    @script ||= Script.new(@build)
  end

  def environment
    Environment.new(@build.env).tap do |env|
      env['BUILDBOX_BUILD_NUMBER'] = @build.number
    end
  end
end

Buildbox.config.update(:worker_access_tokens=> [ "7f068724b9c3215f1d5c" ])

api = API::Client.new

Buildbox.config.worker_access_tokens.each do |access_token|
  api.worker(:access_token => access_token, :hostname => `hostname`.chomp).projects.each do |project|
    running_builds = api.scheduled_builds(project).map do |build|
      Builder.new(build).future(:start)
    end

    # wait for all the running builds to finish
    running_builds.map(&:value)
  end
end

=begin

class Thingy
  include Celluloid

  def initialize(name, i)
    @name = name
    @i =i
  end

  def start
    puts "begin #{@name}"
    sleep 2 * @i
    puts "done #{@name}"
    "success!"
  end
end

futures = []
3.times do |i|
  futures << runner = Thingy.new("keith", i).future(:start)
end

futures.each do |v|
  p v.value
end
=end
