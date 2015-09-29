
require "net/http"
require "uri"
require 'yaml'
require 'json'

module SlackSpace
  
  SLACK_URL=ENV['SLACK_URL']

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

  def push_webhook(payload)
    uri = URI.parse(SLACK_URL)
    response = Net::HTTP.post_form(uri, {:payload=>payload.to_json})

    # This longer way gives you more control.
    # uri = URI.parse(SLACK_URL)
    # http = Net::HTTP.new(uri.host, uri.port)
    # req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    # req.body = {:text=>body['alarm']['label'].to_s}.to_json
    # response = http.request(req)

    puts "PUSH_WEBHOOK: #{response.code} #{response.message}"
    #puts "PUSH_WEBHOOK TO: #{SLACK_URL} RESPONSE: #{response.inspect} : #{response.message} PAYLOAD: #{payload.inspect}"
    response
  end

end

