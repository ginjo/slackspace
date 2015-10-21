require 'bundler'
Bundler.require
Dotenv.load
require 'sinatra/base'
require 'thin'
require_relative 'slackspace.rb'


module SlackSpace

  class App < Sinatra::Base
    enable :sessions, :protection
    set :session_secret, ENV.fetch('SECRET')
  
    helpers SlackSpaceHelpers
    
    # This is really just a placeholder for now.
    get '/' do
      redirect to('https://github.com/ginjo/slackspace')
    end
    
    
    get '/status' do
      "OK"
    end
  
    #post /\/services\/?/ do
    post '/slack/webhook/?' do
      begin
        resp = run_webhook
        status resp.code
        
      rescue
        logger.warn "WEBHOOK FAILED: #{$!}"
        status 500
      end
    end

    # TODO: Complete the test actions.
    get '/slack/test' do
      erb :test
    end
    
    post '/slack/test' do
      halt unless (key=params['key'])
      erb "Received your input"
    end
    


    #####  EXPERIMENTAL - THIS SECTION IS NOT USED FOR PRODUCTION SLACKSPACE APP  #####
    
    get '/rackspace/status' do
      "OK rs_monitor_api: #{rs_monitor_api.object_id} #{rs_monitor_api.credentials[:rackspace_username]} #{rs_monitor_api.credentials[:rackspace_region]}"
    end
    
    # TODO: Store Auth-Token in session!!!
    #
    get "/rackspace/monitors" do
      begin
        api = rs_monitor_api
        @plans = api.list_notification_plans
        #@notifications = api.list_notifications
        @notifications = api.list_notifications
        erb :monitors, :layout=>false
      rescue
        "Rackspace monitors could not be accessed."
      end
    end
    
    get "/rackspace/notifications.xml" do
      @notifications = rs_monitor_api.list_notifications
      content_type "text/xml"
      erb :'notifications.xml', :layout=>false
    end
  
  
  end # App
end # SlackSpace
