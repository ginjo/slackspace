require 'bundler'
Bundler.require
Dotenv.load
require 'sinatra/base'
autoload :SlackSpaceHelpers, './slackspace.rb'



RACKSPACE_CREDENTIALS = {
  :provider           => 'Rackspace',
  :rackspace_api_key  => ENV['RACKSPACE_API_KEY'],
  :rackspace_username => ENV['RACKSPACE_USER_NAME'],
  :rackspace_region   => ENV['RACKSPACE_REGION']
}


module SlackSpace

  class App < Sinatra::Base
    enable :sessions, :protection
    set :session_secret, ENV.fetch('SECRET')
    
    # WHATSTHIS?
    #use Rack::Deflater
  
    helpers SlackSpaceHelpers
    
    get '/status' do
      "OK rs_monitor_api: #{rs_monitor_api.object_id} #{rs_monitor_api.credentials[:rackspace_username]} #{rs_monitor_api.credentials[:rackspace_region]}"
    end
    
    get '/' do
      redirect to('https://github.com/ginjo/slackspace')
    end
  
    #post /\/services\/?/ do
    post '/services/?' do
      begin
        resp = run_webhook
        status resp.code
        
      rescue
        puts "WEBHOOK FAILED: #{$!}"
        status 500
      end
    end
    
    # TODO: Store Auth-Token in session!!!
    #
    get "/monitors" do
      api = rs_monitor_api
      @plans = api.list_notification_plans
      #@notifications = api.list_notifications
      @notifications = api.list_notifications
      erb :monitors
    end
    
    get "/notifications.xml" do
      @notifications = rs_monitor_api.list_notifications
      content_type "text/xml"
      erb :'notifications.xml'
    end
  
  
  end # App
end # SlackSpace
