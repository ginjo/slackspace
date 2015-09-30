
require "net/http"
require "uri"
require 'yaml'
require 'json'
require 'fog'

module SlackSpace
    
  def endpoint
    params[:endpoint] || ENV['SLACK_URL']
  end

  def run_webhook
    body = request.body.read.to_s
    #puts "RUN_WEBHOOK BODY #{body}"
    webhook = parse_webhook(body)
    payload = build_payload(webhook)
    push_webhook(payload)
  end

  def parse_webhook(body)
    webhook = JSON.load(body)
  end
  
  def build_payload(webhook)
    { :text => "Rackspace Notification *#{webhook['details']['state']}*",
      :attachments => build_attachments(webhook),
      :username => "SlackSpace",
      :icon_emoji => ":ghost:"
    }
  end
  
  def build_attachments(webhook)
    state = webhook['details']['state']
    level = case state
      when 'CRITICAL'; 'danger'
      when 'WARNING'; 'warning'
      when 'OK'; 'good'
    end
    
    [
      {
        "fallback" => "Your browser does not support full display of the Rackspace alarm.",
  
        "color" => level,
  
        #"pretext" => "Optional text that appears above the attachment block",
  
        #"author_name" => "Bobby Tables",
        #"author_link" => "http://flickr.com/bobby/",
        #"author_icon" => "http://flickr.com/icons/bobby.jpg",
  
        "title" => webhook['alarm']['label'].to_s,
        #"title_link" => "https://api.slack.com/",
  
        "text" => JSON.pretty_generate(webhook) #"Optional text that appears within the attachment",
  
        # "fields" => [
        #     {
        #         "title" => "Priority",
        #         "value" => "High",
        #         "short" => false
        #     }
        # ],
  
        #"image_url" => "http://my-website.com/path/to/image.jpg",
        #"thumb_url" => "http://example.com/path/to/thumb.png"
      }
    ]
  end

  def push_webhook(endpoint=endpoint, payload)
    uri = URI.parse(endpoint)
    response = Net::HTTP.post_form(uri, {:payload=>payload.to_json})

    # This longer series of steps gives you more control over the connection, but so far it isn't necessary.
    # uri = URI.parse(SLACK_URL)
    # http = Net::HTTP.new(uri.host, uri.port)
    # req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    # req.body = {:text=>body['alarm']['label'].to_s}.to_json
    # response = http.request(req)

    puts "PUSH_WEBHOOK: #{response.code} #{response.message}"
    #puts "PUSH_WEBHOOK TO: #{SLACK_URL} RESPONSE: #{response.inspect} : #{response.message} PAYLOAD: #{payload.inspect}"
    response
  end
  
  def rackspace_fog_monitoring_api
    @monitoring ||= Fog::Monitoring.new(RACKSPACE_CREDENTIALS)
  end
  
  def rackspace_hg_monitoring_api
  
  end

end

class RackspaceApi

  attr_accessor :credentials

  def initialize(credentials=RACKSPACE_CREDENTIALS)
    @credentials = credentials
  end
  
  def submit_api_request(url, http_method=:get, data=nil)
    # uri = URI.parse(url)
    # http = Net::HTTP.new(uri.host, uri.port)
    # req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    # req.body = {:text=>body['alarm']['label'].to_s}.to_json
    # response = http.request(req)
  end
  
  def  authenticate()
    # curl -s https://identity.api.rackspacecloud.com/v2.0/tokens -X 'POST' \
    #      -d '{"auth":{"RAX-KSKEY:apiKeyCredentials":{"username":"'$USER_NAME'", "apiKey":"'$API_KEY'"}}}' \
    #      -H "Content-Type: application/json" | python -m json.tool | tee rs_authenticate_response.json
    #      
    # TENANT_ID=`cat rs_authenticate_response.json | python -c 'import sys, json; print json.load(sys.stdin)["access"]["token"]["tenant"]["id"]'`
    # AUTH_TOKEN=`cat rs_authenticate_response.json | python -c 'import sys, json; print json.load(sys.stdin)["access"]["token"]["id"]'`
  end
  
  #   request_json () {
  # 	if [ ! -t 0 ]; then
  # 		local data="`cat -`"
  # 	fi
  # 	local url=$1
  # 	local method=${2:-GET}
  # 	
  # 	if [ "$data" ]; then
  # 		curl -s $url \
  # 		     -X $method \
  # 		     -d "$data" \
  # 		     -H "Content-Type: application/json" \
  # 		     -H "X-Auth-Token: $AUTH_TOKEN" | python -m json.tool
  # 	else
  # 		curl -s $url \
  # 		     -X $method \
  # 		     -H "X-Auth-Token: $AUTH_TOKEN" | python -m json.tool
  # 	fi
  #   }
  
end

class RackspaceMonitoringApi < RackspaceApi

  #   # List cloud monitor notifications
  #   rs_list_notifications () {
  #   	request_json "https://monitoring.api.rackspacecloud.com/v1.0/$TENANT_ID/notifications" | tee rs_list_notifications_response.json
  #   }
  #   
  #   
  #   # Test cloud monitor notification, before creating it.
  #   rs_test_notification () {
  #   	{ request_json "https://monitoring.api.rackspacecloud.com/v1.0/$TENANT_ID/test-notification" POST | tee rs_test_notification_response.json; } <<-EEOOFF
  #   		{
  #   		   "type": "webhook",
  #   		   "details": {
  #   		      "url": "https://slackspace.herokuapp.com/?endpoint=https://hooks.slack.com/services/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"
  #   		   }
  #   		}
  #   	EEOOFF
  #   }
  #   
  #   # Create cloud monitor notification for webhook
  #   rs_create_notification () {
  #   	{ request_json "https://monitoring.api.rackspacecloud.com/v1.0/$TENANT_ID/notifications" POST | tee rs_create_notification_response.json; } <<-EEOOFF
  #   		{
  #   		   "label": "cerneops.slack.com",
  #   		   "type": "webhook",
  #   		   "details": {
  #   		      "url": "https://hooks.slack.com/services/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"
  #   		   }
  #   		}
  #   	EEOOFF
  #   }
  #   
  #   # Test existing notification (notification-id)
  #   rs_test_notifications () {
  #   	request_json "https://monitoring.api.rackspacecloud.com/v1.0/$TENANT_ID/notifications/$1/test" | tee rs_test_notification_response.json
  #   }
  #   
  #   # List cloud monitor notification plans
  #   rs_list_notification_plans () {
  #   	request_json "https://monitoring.api.rackspacecloud.com/v1.0/$TENANT_ID/notification_plans" | tee rs_list_notification_plans_response.json
  #   }
  #   
  #   # Show cloud monitor notification (notification-plan-id)
  #   # Params: notification-plan-id
  #   rs_show_notification_plan () {
  #   	request_json "https://monitoring.api.rackspacecloud.com/v1.0/$TENANT_ID/notification_plans/$1" | tee rs_show_notification_plan_response.json
  #   }
  #   
  #   # Create cloud monitor notification plan (label, notify-id-critical, notify-id-warning, notify-id-ok)
  #   rs_create_notification_plan () {
  #   	{ request_json "https://monitoring.api.rackspacecloud.com/v1.0/$TENANT_ID/notification_plans" POST | tee rs_create_notification_plan_response.json; } <<-EEOOFF
  #   		{
  #   	    "label": "$1",
  #   	    "critical_state": [
  #   	      "$2"
  #   	    ],
  #   	    "warning_state": [
  #   	      "$3"
  #   	    ],
  #   	    "ok_state": [
  #   	      "$4"
  #   	    ]
  #   		}
  #   	EEOOFF
  #   }

end

