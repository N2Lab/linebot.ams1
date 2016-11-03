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
    user_event = UserEvent.insert(BOT_ID, mid, event.to_json, profile.to_json) 

    # reply
    text = "投稿ありがとう！"
     actions = [
                {
                  type: "uri",
                  label: "全ユーザーの投稿を見る",
                  uri: "https://ams1.n2bot.net/bot15_n2realtimefaq/show?bot_id=#{BOT_ID}&user_event_id=#{user_event.id}"
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
  
  # PC/SPブラウザ向け ユーザーの投稿を閲覧するhtmlを返す
  def show()
    bot_id = params[:bot_id]
    user_event_id = params[:user_event_id]
    Rails.logger.debug("show bot_id=#{bot_id} user_event_id=#{user_event_id}")
    
    # 10個前のメッセージから表示開始
    last_ue = UserEvent.where(:bot_id => bot_id).order(:id => "desc").limit(10).last
    Rails.logger.debug("last_ue=#{last_ue.inspect}")
    @start_user_event_id =  last_ue.try(:id)
    
  end
  
  # ajax 最新投稿をフェッチして返す
  def fetch()
    @last_user_event_id = params[:last_user_event_id]
    
    
  end
end
