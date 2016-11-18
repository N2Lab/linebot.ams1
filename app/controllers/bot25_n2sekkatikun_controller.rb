# N2 せっかち君
# 
class Bot25N2Controller < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  require 'kconv'
  require 'active_support/core_ext/hash/conversions'
  
  BOT_ID = 25
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "56ea561f5f1ddf589140cd3ee51e1851"
      config.channel_token = "bMdRbN/K0z6ZxSj3CS51xXbbS5S59ZMnx1sVYWLzxC4+1xCulsNTDcJcCOxWGKxT66xCbjC2b37RwelGpvvMIvdP5EwUdu78tpGBMwUjNPZqJUJsoPGicj7fUasZBGEwjVVl+ACJI3zeJJZTfAG2JwdB04t89/1O/w1cDnyilFU="
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
          message = execute_reply(event)
          response = client.reply_message(event['replyToken'], message) unless message.blank?
          
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
  
  GOOGLE_API_KEY = "AIzaSyAbAK1ASX-AnyDe9QEcurKplj7ajDMmIxI"
  
  # 返信 親
  def execute_reply(event)
    text = event.message['text']
    messages = []
    
    # 1. call Google Cloud Natural Language API and parse
    #  language.documents.analyzeEntities = Entities（固有表現抽出）
    #  Syntax（形態素解析、係り受け解析）
    # まずは Entities で Location > ルート検索 などを対応する
    res = google_api_natural_lang_entities(GOOGLE_API_KEY, text)

    messages << {
      type: 'text',
      text: res.inspect
    }
  end

end
