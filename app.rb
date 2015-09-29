require 'bundler'
Bundler.require

require 'sinatra/base'
autoload :SlackSpace, './slackspace.rb'

Dotenv.load

class App < Sinatra::Base
  enable :sessions, :protection
  set :session_secret, ENV.fetch('SECRET')
  
  # WHATSTHIS?
  #use Rack::Deflater

  helpers SlackSpace
  
  get '/status' do
    "OK"
  end

  post '/*' do
    begin
      resp = run_webhook
      status resp.code
      
    rescue
      puts "WEBHOOK FAILED: #{$!}"
      status 500
    end
  end


end
