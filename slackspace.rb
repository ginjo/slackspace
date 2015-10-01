
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

    logger.info "PUSH_WEBHOOK: #{response.code} #{response.message}"
    #puts "PUSH_WEBHOOK TO: #{SLACK_URL} RESPONSE: #{response.inspect} : #{response.message} PAYLOAD: #{payload.inspect}"
    response
  end
  
  def rackspace_fog_monitoring_api
    @monitoring ||= Fog::Monitoring.new(RACKSPACE_CREDENTIALS)
  end
  
  def rackspace_hg_monitoring_api
  
  end

end # SlackSpace


class RackspaceApi

  attr_accessor :credentials, :tennant_id, :auth_token, :last_response, :auth_response

  def initialize(credentials=RACKSPACE_CREDENTIALS)
    @credentials = credentials
    self
  end
  
  # Generic comprehensive single-method call for Net::HTTP
  # Gist this?
  def submit_request(url, http_method=:get, data=nil, headers={})
    uri = URI.parse(url)
    host = uri.host || 'localhost'
    port = uri.port || 80
    path = uri.path || '/'
    connection = Net::HTTP.new(host, port)
    connection.use_ssl=true if uri.scheme.to_s == 'https'
    @last_response = connection.start do |http|
      req = case http_method.to_sym
        when :get; Net::HTTP::Get.new(path, headers)
        when :post; Net::HTTP::Post.new(path, headers.merge({'Content-Type' =>'application/json'}))
        when :put; Net::HTTP::Put.new(path, headers.merge({'Content-Type' =>'application/json'}))
        when :delete; Net::HTTP::Delete.new(path, headers)
      end
      req.body = data
      rsp = http.request(req)
      #puts rsp.body
      #puts rsp.to_hash.inspect
      rsp
    end
  end
  
  # Wrap generic request with auth credentials, and return json.
  def request_json(url, http_method=:get, data=nil, headers={})
    from_json(submit_request(url, http_method, data, headers.merge({'X-Auth-Token'=>auth_token})).body)
  end
  
  def from_json(txt)
    JSON.load(txt)
  end
  
  def auth_token
    @auth_token || authenticate
    @auth_token
  end
  
  def tennant_id
    @tennant_id || authenticate
    @tennant_id
  end
    
  # Authenticate Rackspace user and store tennatn_id & auth_token.
  def  authenticate
    resp = submit_request(
      'https://identity.api.rackspacecloud.com/v2.0/tokens',
      :post,
      {auth:{"RAX-KSKEY:apiKeyCredentials" => {username:credentials[:rackspace_username], apiKey:credentials[:rackspace_api_key]}}}.to_json
    )
    @auth_response = resp
    resp = from_json(@auth_response.body)
    @tennant_id = resp["access"]["token"]["tenant"]["id"]
    @auth_token = resp["access"]["token"]["id"]
    resp
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
  
end # RackspaceApi



class RackspaceMonitoringApi < RackspaceApi

  # List cloud monitor notifications
  def list_notifications
  	request_json("https://monitoring.api.rackspacecloud.com/v1.0/#{tennant_id}/notifications")
  end
  #   
  #
  # Show cloud monitor notification (notification-plan-id)
  # Params: notification-plan-id
  def show_notification(notification_id)
  	request_json("https://monitoring.api.rackspacecloud.com/v1.0/#{tennant_id}/notifications/#{notification_id}")
  end
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
  # Test existing notification (notification-id)
  def test_notifications(notification_id)
  	request_json("https://monitoring.api.rackspacecloud.com/v1.0/#{tennant_id}/notifications/#{notification_id}/test", :post)
  end

  # List cloud monitor notification plans
  def list_notification_plans
  	request_json("https://monitoring.api.rackspacecloud.com/v1.0/#{tennant_id}/notification_plans")
  end
  
  # Show cloud monitor notification (notification-plan-id)
  # Params: notification-plan-id
  def show_notification_plan(plan_id)
  	request_json("https://monitoring.api.rackspacecloud.com/v1.0/#{tennant_id}/notification_plans/#{plan_id}")
  end
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

