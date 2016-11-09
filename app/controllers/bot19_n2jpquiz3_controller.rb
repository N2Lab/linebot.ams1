# 日本地図都道府県クイズ３択
# 
class Bot19N2jpquiz3Controller < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  
  BOT_ID = 19
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "b3ff1a1f5b22d6096a54148acdc575fc"
      config.channel_token = "EksKcc1u+F62Fr1sVhXvT2UV7K1UZG18JNhu9CzTh9HVkuUrZNdaVDdiDFPaEnwRZHNdQvuZnc7naIn20pCb1jcnn/LGZy3ahpm2DGiHs5BWuzCSkB5pPtMSQjtVIwgKTtusy+ycP1AGGNSW1puDAwdB04t89/1O/w1cDnyilFU="
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
          message = execute_start_map(event, true)
          response = client.reply_message(event['replyToken'], message)
        
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = execute_start_map(event)
          response = client.reply_message(event['replyToken'], message)
          
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          message = execute_start_map(event)
          response = client.reply_message(event['replyToken'], message)
          
          # response = client.get_message_content(event.message['id'])
          # tf = Tempfile.open("content")
          # tf.write(response.body)
        end
      when Line::Bot::Event::Postback # 回答した
#        response = client.reply_message(event['replyToken'], execute_postback(event))
      end
    }
    
    Rails.logger.debug("response=#{response.try(:code)} #{response.try(:body)}")
  
    render text: ""
  end
  
  # 新しく問題を発行
  def execute_start_map(event, follow_flg = false)
    # get user info
    mid = event['source']['userId']
    profile = get_profile(@client, mid)
    
    messages = []
    
    if follow_flg
      messages << {
            type: 'text',
            text: "友だち登録ありがとうございます(happy)
N2日本地図３択は、地図上の都道府県がどの県か３択で回答し続けるアカウントです。
是非末永くご利用ください。

本アカウントに関するお問合わせは
https://www.facebook.com/n2lab.inc/
にメッセージ送信でお願いします。(grin)"
          }
    end
    
    messages << create_qa()
     
    # save
    # user_event = UserEvent.insert(BOT_ID, mid, event.to_json, profile.to_json) 

    # reply
    messages
  end
  
  def create_qa()
    text = "ここは何県（なにけん）？"
     actions = [
                {
                    type: "postback",
                    label: "和歌山県",
                    data: {:action_pref => 20, :answer_pref => 10}.to_s
                },
                {
                    type: "postback",
                    label: "和歌山県",
                    data: {:action_pref => 20, :answer_pref => 10}.to_s
                },
                {
                    type: "postback",
                    label: "和歌山県",
                    data: {:action_pref => 20, :answer_pref => 10}.to_s
                },
    ]
    
      {
        type: "template",
        altText: text,
        template: {
            type: "confirm",
            text: text,
            actions: actions
        }
      }      
    
  end
  

end
