require 'bundler'
Bundler.require
Dotenv.load
require 'sinatra/base'
require 'thin'
require 'tilt/erb'
require_relative 'slackspace.rb'

# Start this app with 'bundle exec rackup -o0.0.0.0'
# or 'bundle exec thin --threaded -p8000 start'
# or bundle exec thin start -p 8000 --threaded --ssl --ssl-key-file <path-to-key-file> --ssl-cert-file <path-to-cert-file>
# Note: you need threaded or multiple instances to handle testing that goes to rackspace --> slackspace --> slack,
# because the app needs to receive a rackspace webhook, while your http request is waiting for rackspace to respond.

# To load this app in irb for testing
# bundle exec irb -I./ -r app.rb

# Note that loading specific rackspace or slack credentials from the .env file is intended for
# private instances of this app running on tightly controlled servers. Otherwise, all credentials
# should be managed thru rackspace, slack, or thru the web UI of this app.


### TODO: Eliminate 'key=' param in rackspace-to-slackspace api. Use the uri-string as the 'id='  param.
### TODO: 


module SlackSpace

  extend SlackSpaceHelpers

  class App < Sinatra::Base
    enable :sessions, :protection, :logging
    set :session_secret, ENV.fetch('SECRET')
  
    helpers SlackSpaceHelpers
    
    before do
      ### Sessions or Credentials won't load properly unless this is here
      credentials[:slack]
      
      #puts "PARAMS #{params.to_yaml}"
      #puts "SESSION_CREDENTIALS #{session['credentials'].inspect}"
      #puts "LOADED_CREDENTIALS #{credentials.inspect}"
      credentials[:slack] = {:webhook_key=>params['slack_key']} if !params['slack_key'].to_s.empty?
      credentials[:rackspace] = {
        :rackspace_region => params['rs_region'],
        :rackspace_username => params['rs_username'],
        :rackspace_api_key => params['rs_key'],
      } if (!params['rs_username'].to_s.empty? && !params['rs_key'].to_s.empty?)
      
      true
    end
    
    after do
      #puts "AFTER PACK_CREDENTIALS: #{@credentials.inspect}"
      pack_credentials
      
      true
    end
    
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
        resp = run_webhook(request.body.read.to_s)
        status resp.code
        
      rescue
        #logger.warn "WEBHOOK FAILED: #{$!}"
        puts "/slack/webhook error: #{$!}"
        status 500
      end
    end

    # TODO: Complete the test actions.
    get '/slack/test' do
      #puts "SLACK/TEST credentials #{credentials.to_yaml}"  # TODO: Remove this for production!
      erb :test
    end
    
    post '/slack/test' do
      case
      when(params['test_slack'] && credentials[:slack])
        key = credentials[:slack][:webhook_key]
        #payload=File.read('mock_notification.json')
        timestamp_integer = Time.now.to_i
        payload = erb(:'mock_rackspace_notification.json', :locals=>{:timestamp_integer=>timestamp_integer}, :layout=>false)
        puts "PAYLOAD:"
        puts payload.to_s
        puts "END_PAYLOAD"
        resp = run_webhook(endpoint(key), payload)
        status resp.code
        #resp.message
        "<pre>#{resp.to_yaml}</pre>"
      when(params['test_rackspace'] && credentials[:rackspace] && credentials[:slack])
        slack_key = credentials[:slack][:webhook_key]
        api = rs_monitor_api(credentials[:rackspace])
        credentials[:rackspace] = api.authenticate
        # Probably should disable these puts for production, as api object will contain sensitive data.
        #puts "SLACK/TEST test_rackspace rs_monitor_api:"
        #puts api.to_yaml
        resp = api.test_notification(slack_key)
        #resp = api.list_notifications
        "<pre>#{resp.to_yaml}</pre>"
      else
        redirect back
      end
    end
    


    #####  EXPERIMENTAL - THIS SECTION IS NOT USED FOR PRODUCTION SLACKSPACE APP  #####
    
    get '/rackspace/status' do
      "OK rs_monitor_api: #{rs_monitor_api.object_id} #{rs_monitor_api.credentials[:rackspace_username]} #{rs_monitor_api.credentials[:rackspace_region]}"
    end
    
    # TODO: Store Auth-Token in session!!!
    #
    get "/rackspace/monitors" do
      begin
        api = rs_monitor_api(credentials[:rackspace])
        @plans = api.list_notification_plans
        #@notifications = api.list_notifications
        @notifications = api.list_notifications
        erb :monitors, :layout=>false
      rescue
        "Rackspace monitors could not be accessed."
      end
    end
    
    get "/rackspace/notifications.xml" do
      begin
      @notifications = rs_monitor_api.list_notifications
      content_type "text/xml"
      erb :'notifications.xml', :layout=>false
      rescue
        erb "ERROR: #{$!}"
      end
    end
  
  
  end # App
end # SlackSpace
