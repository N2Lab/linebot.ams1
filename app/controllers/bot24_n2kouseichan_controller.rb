# N2 校正ちゃん
# 
class Bot24N2kouseichanController < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  require 'kconv'
  require 'active_support/core_ext/hash/conversions'
  
  BOT_ID = 24
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "970fab5722c07e20c2d1bdc83905d97f"
      config.channel_token = "IJE3nxtm9511RL1/EaFdWg6esb3ofO0bMGraOuE/gz/OZJNmdpt1pQdENSeDft85osErFlItvdWy6aJBtQPOfXSEu5dOUZ4iBdhMGFWPXEe+7OxLRdYRTgg2mqmU6OZNBQ1JXFH5EzQ9yKX4xclpFgdB04t89/1O/w1cDnyilFU="
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
    response = nil
    events.each { |event|
      case event
      when Line::Bot::Event::Follow
          # message = execute_start_map(event, true)
          # response = client.reply_message(event['replyToken'], message)
        
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = execute_kousei(event)
          response = client.reply_message(event['replyToken'], message)
          
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          # message = execute_start_map(event)
          # response = client.reply_message(event['replyToken'], message)
          
          # response = client.get_message_content(event.message['id'])
          # tf = Tempfile.open("content")
          # tf.write(response.body)
        end
      # when Line::Bot::Event::Postback # 回答したので答え合わせ
        # message = execute_answer_check(event)
        # response = client.reply_message(event['replyToken'], message)
      end
    }
    
    Rails.logger.debug("response=#{response.try(:code)} #{response.try(:body)}")
  
    render text: ""
  end
  
  # 校正実行
  def execute_kousei(event)
    text = event.message['text']
    messages = []
    
    # call kousei api
    url = "http://jlp.yahooapis.jp/KouseiService/V1/kousei"
    params = {:appid => "dj0zaiZpPThFM1E1aHBqaUZHZCZzPWNvbnN1bWVyc2VjcmV0Jng9ZTE-",
      :sentence => text,
      :filter_group => 1,
      }
    res = Net::HTTP.post_form(URI.parse(url),params)
    hash = Hash.from_xml(res.body)

    Rails.logger.debug("hash=#{hash.inspect}")

    messages << {
      type: 'text',
      text: hash.to_s
    }
  end

end
