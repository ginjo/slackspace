require 'bundler'
Bundler.require

require 'sinatra/base'
autoload :SlackSpace, './slackspace.rb'

Dotenv.load

RACKSPACE_CREDENTIALS = {
  :provider           => 'Rackspace',
  :rackspace_api_key  => ENV['RACKSPACE_API_KEY'],
  :rackspace_username => ENV['RACKSPACE_USER_NAME'],
  :rackspace_region   => ENV['RACKSPACE_REGION']
}

RS_MONITOR = Fog::Monitoring.new(RACKSPACE_CREDENTIALS)

class App < Sinatra::Base
  enable :sessions, :protection
  set :session_secret, ENV.fetch('SECRET')
  
  # WHATSTHIS?
  #use Rack::Deflater

  helpers SlackSpace
  
  get '/status' do
    "OK"
  end
  
  get '/' do
    redirect to('https://github.com/ginjo/slackspace')
  end

  post /\/services\/?/ do
    begin
      resp = run_webhook
      status resp.code
      
    rescue
      puts "WEBHOOK FAILED: #{$!}"
      status 500
    end
  end


end
