class Bot1FlashanzanController < ActionController::Base

  require 'line/bot'

  skip_before_action :verify_authenticity_token

  def client
    @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = "b093a614227cef8191fb0aad8eeeb0d8"
    config.channel_token = "G22jOdiQ9AfPOqPB/OdwHsKwotWtFRKbcS3G+KzGZecGLAA0nfdS0zhMcvSduIvzdPC2L2sffP9wvXbmGt0qXyb8zVuhTOQJAKx23XDHNC/3Vyh9er3Ls98J3b9is66dSLanJAMPhrayYIoxYLFnBQdB04t89/1O/w1cDnyilFU="
    }
  end

  def index
    body = request.raw_post
#    body = request.body.read, {:symbolize_names => true}
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
  
    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: event.message['text']
          }
          client.reply_message(event['replyToken'], message)
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      end
    }
  
    "OK"
  end
end
