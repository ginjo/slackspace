# hello_world.rb
require 'bundler'
Bundler.require

require 'rack'
require 'rack/server'
require 'yaml'

class HelloWorld
  def response(body)
    [200, {}, Rack::Request.new(body).params.to_yaml || 'Hello World']
  end
end

class HelloWorldApp
  def self.call(env)
    HelloWorld.new.response(env)
  end
end

# Must use capital 'Port' here, if you want to change the port from default.
Rack::Server.start :app => HelloWorldApp, :Port=>8000

