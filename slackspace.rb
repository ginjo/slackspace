require "net/http"
require "uri"
require 'yaml'
require 'json'
require 'fog'


RACKSPACE_CREDENTIALS = {
  :provider           => 'Rackspace',
  :rackspace_api_key  => ENV['RACKSPACE_API_KEY'],
  :rackspace_username => ENV['RACKSPACE_USER_NAME'],
  :rackspace_region   => ENV['RACKSPACE_REGION']
}

SLACK_WEBHOOK = "https://hooks.slack.com/services/"


module SlackSpaceHelpers
    
  # params[:endpoint] should be a valid Slack incoming-webhook URL.
  def endpoint
    "#{SLACK_WEBHOOK}#{params[:key]}"
  end

  # Master call to process webhook.
  def run_webhook
    body = request.body.read.to_s
    #puts "RUN_WEBHOOK BODY #{body}"
    webhook = JSON.load(body)
    payload = build_payload(webhook)
    push_webhook(payload)
  end

  #   # Get webhook json payload as ruby object.
  #   # This isn't really necessary.
  #   def parse_webhook(body)
  #     webhook = JSON.load(body)
  #   end
  
  # Build Slack incommin-webhook payload.
  def build_payload(webhook)
    { :text => "Rackspace Notification",
      :attachments => build_attachments(webhook),
      :username => "SlackSpace",
      :icon_emoji => ":ghost:"
    }
  end
  
  # Build Slack incomming-webhook attachments.
  def build_attachments(webhook)
    state = webhook['details']['state']
    state_color = case state
      when 'CRITICAL'; 'danger'
      when 'WARNING'; 'warning'
      when 'OK'; 'good'
    end
    target = webhook['details']['target']
    timestamp = Time.at(webhook['details']['timestamp'].to_i/1000).to_s
    entity_label = webhook['entity']['label']
    entity_ip_address = webhook['entity']['ip_addresses']['default']
    check_label = webhook['check']['label']
    #check_details = webhook['check']['details'].to_yaml
    alarm_label = webhook['alarm']['label']
    
    [
      {
        "fallback" => "Your browser does not support full display of the Rackspace alarm.",
  
        "color" => state_color,
  
        #"pretext" => "Optional text that appears above the attachment block",
  
        #"author_name" => "Bobby Tables",
        #"author_link" => "http://flickr.com/bobby/",
        #"author_icon" => "http://flickr.com/icons/bobby.jpg",
  
        "title" => state,
        #"title_link" => "https://api.slack.com/",
  
        #"text" => JSON.pretty_generate(webhook) #"Optional text that appears within the attachment",
  
        "fields" => [
          {
            "title" => "Target",
            "value" => target,
            "short" => true
          },
          {
            "title" => "Timestamp",
            "value" => timestamp,
            "short" => true
          },
          {
            "title" => "Entity",
            "value" => entity_label,
            "short" => true
          },
          {
            "title" => "IP",
            "value" => entity_ip_address,
            "short" => true
          },
          {
            "title" => "Check",
            "value" => check_label,
            "short" => true
          },
          {
            "title" => "Alarm",
            "value" => alarm_label,
            "short" => true
          }
        ],
  
        #"image_url" => "http://my-website.com/path/to/image.jpg",
        #"thumb_url" => "http://example.com/path/to/thumb.png"
      }
    ]
  end

  # Push formatted json webhook to Slack.
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


  ## These are for working with Rackspace Monitoring API.
  
  def plan_notifications(plan, type)
    #@notifications['values'].find{|n| n['id'] == [plan['critical_state']].flatten[0].to_s }['label'] rescue plan['critical_state']
    [plan["#{type}_state"]].flatten.collect{|id| @notifications['values'].find{|n| n['id'] == id}}
  end
    
  def rs_fog_monitor_api(auth = session[:credentials] || RACKSPACE_CREDENTIALS)
    @rs_fog_monitor_api ||= Fog::Monitoring.new(auth)
  end
  
  def rs_monitor_api(auth = session[:credentials] || RACKSPACE_CREDENTIALS)
    @rs_monitor_api ||= RackspaceMonitoringApi.new(auth)
  end

end # SlackSpace


# Query & Control Rackspace API
#
# This will allow users to manange Rackspace Monitoring notifications and notification plans,
# services for which Rackspace still has no web interface.
#
class RackspaceApi

  attr_accessor :credentials, :last_response, :auth_response

  def initialize(credentials)
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
    credentials[:auth_token] || authenticate[:auth_token]
  end
  
  def tennant_id
    credentials[:tennant_id] || authenticate[:tennant_id]
  end
    
  # Authenticate Rackspace user and store tennant_id & auth_token.
  def  authenticate
    if credentials[:auth_token] && credentials[:tennant_id]
      #credentials
    else
      puts "RackspaceApi#authenticate"
      resp = submit_request(
        'https://identity.api.rackspacecloud.com/v2.0/tokens',
        :post,
        {auth:{"RAX-KSKEY:apiKeyCredentials" => {username:credentials[:rackspace_username], apiKey:credentials[:rackspace_api_key]}}}.to_json
      )
      @auth_response = resp
      resp = from_json(@auth_response.body)
      credentials[:tennant_id] = resp["access"]["token"]["tenant"]["id"]
      credentials[:auth_token] = resp["access"]["token"]["id"]
    end
    credentials
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
  # Test cloud monitor notification, before creating it.
  def test_notification
  	request_json("https://monitoring.api.rackspacecloud.com/v1.0/#{tennant_id}/test-notification", :post, <<-EEOOFF)
      {
        "type": "webhook",
        "details": {
          "url": "http://rack05.cernesystems.com:8000/services/?endpoint=https://hooks.slack.com/services/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"
        }
      }
  	EEOOFF
  end
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

