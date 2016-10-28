# N2リアFAQ
# ユーザーからの発言をPCブラウザページにリアルタイム表示してくれるbot。スタンプ, 絵文字もある程度表示可能。縦スクロール風も可能
class Bot15N2realtimefaqController < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  
  BOT_ID = 15
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "8c7f33d6e2722aad1e18d46e0843daee"
      config.channel_token = "XBkpz/GCf7X5zF1HvGz2Ht5d+c1ltnfbQhX0jUBeLsnVhVyNm2QYODHHPWhY3v9HOSPAousIGwpUdjdXcJIke6pFgf2bE18vmY0EANv0IfXZr3/YJc+VjIUxrLJHlQ6owYWWqlfQtL3/wevWEH5caQdB04t89/1O/w1cDnyilFU="
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
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = execute_text(event)
          response = client.reply_message(event['replyToken'], message)
          
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      when Line::Bot::Event::Postback # 他の画像
#        response = client.reply_message(event['replyToken'], execute_postback(event))
      end
    }
    
    Rails.logger.debug("response=#{response.try(:code)} #{response.try(:body)}")
  
    render text: ""
  end
  
  # メッセージ受信内容保存 & 応答
  def execute_text(event)
    # get user info
    mid = event['source']['userId']
    profile = get_profile(@client, mid)
    
    # save
    event_hash = JSON.parse(event.to_json)
    event_hash["profile"] = profile
    
    attr = Attr.insert(BOT_ID, mid, 1, 1, event_hash.to_json) # NO=1 を受信msg, val はダミー

    # reply
    text = "投稿ありがとう！"
     actions = [
                {
                  type: "uri",
                  label: "全ユーザーの投稿を見る",
                  uri: "https://ams1.n2bot.net/bot15_n2realtimefaq/show?attr_id=#{attr.id}"
                }
    ]
    return [
      {
        type: "template",
        altText: text,
        template: {
            type: "confirm",
            text: text,
            actions: actions
        }
      }      
   ] 
    
  end
  
  # PC/SPブラウザ向け ユーザーの投稿を閲覧する
  def show()
    
  end
end
