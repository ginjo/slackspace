require 'bundler'
Bundler.require

require 'rack'
require 'rack/server'
require "net/http"
require "uri"
require 'yaml'
require 'json'

SLACK_URL="https://hooks.slack.com/services/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"

class HelloWorld
  def response(output)
    [200, {}, output || 'Hello World']
  end
end

class HelloWorldApp
  def self.call(env)
    body=Rack::Request.new(env).body
    webhook = parse_webhook(body)
    begin
      rslt = push_webhook(webhook)
      [200, {}, rslt.to_s]
    rescue
      puts "ERROR: #{$!}"
      [500, {}, $!.to_s]
    end
  end

  def self.parse_webhook(body)
    #puts "PARSE_WEBHOOK #{body}"
    webhook = JSON.load(body)
    #puts webhook.to_yaml
    webhook
  end
  
  def self.push_webhook(body)
    uri = URI.parse(SLACK_URL)
    response = Net::HTTP.post_form(uri, {:payload=>{:text=>body['alarm']['label'].to_s + body.to_yaml}.to_json})
    
    # uri = URI.parse(SLACK_URL)
    # http = Net::HTTP.new(uri.host, uri.port)
    # req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    # req.body = {:text=>body['alarm']['label'].to_s}.to_json
    # response = http.request(req)
    
    puts "PUSH_WEBHOOK #{response.inspect}"
    response
  end
end

# Must use capital 'Port' here, if you want to change the port from default.
Rack::Server.start :app => HelloWorldApp, :Port=>8000, :Host=>'0.0.0.0'








# POST DATA


# uri = URI.parse("http://example.com/search")
# 
# # Shortcut
# response = Net::HTTP.post_form(uri, {"q" => "My query", "per_page" => "50"})
# 
# # Full control
# http = Net::HTTP.new(uri.host, uri.port)
# 
# request = Net::HTTP::Post.new(uri.request_uri)
# request.set_form_data({"q" => "My query", "per_page" => "50"})
# 
# response = http.request(request)


# OR FOR RAW JSON BODY
# def create_agent
#     uri = URI('http://api.nsa.gov:1337/agent')
#     http = Net::HTTP.new(uri.host, uri.port)
#     req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
#     req.body = {name: 'John Doe', role: 'agent'}.to_json
#     res = http.request(req)
#     puts "response #{res.body}"
# rescue => e
#     puts "failed #{e}"
# end
