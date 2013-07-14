#!/usr/bin/env ruby

require 'rubygems'

require 'hashie/dash'
require 'pathname'
require 'json'

class Configuration < Hashie::Dash
  property :worker_uid
  property :endpoint, :default => "http://api.buildbox.dev/v1"

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
    merge JSON.parse(path.read)
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

    def user
      get("user")
    end

    def builds
      get("workers/#{SecureRandom.uuid}/builds")
    end

    private

    def connection
      @connection ||= Faraday.new(:url => @config.endpoint) do |faraday|
        faraday.request  :json

        faraday.response :logger
        faraday.response :mashify

        # json needs to come after mashify as it needs to run before the mashify
        # middleware.
        faraday.response :json

        faraday.adapter Faraday.default_adapter
      end
    end

    def get(path)
      connection.get(path).body
    end
  end
end

p API::Client.new.builds

=begin
require 'celluloid'

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
