# BOT Awardsハッカソン
class Bot100Controller < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  
  BOT_ID = 100
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "814c6c0b2fe1004513c420005e21bb7f"
      config.channel_token = "GvqwGLjd5JYo1LXhtpBMZk5tzhz+pKbsyhavfzJLE98wCzUGYIFXudPFvrPb5cvit2DFpeyF/xnLVyCgWkkVzTOU22Lu0mS5D9ywHl52rqrrSWIESp95d3EXeBSeTpo8zX98IXDqUXfYBcFBmzO8RgdB04t89/1O/w1cDnyilFU="
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
    text = "投稿ありがとう！
PCブラウザで表示する方はこちらからどうぞ。
https://ams1.n2bot.net/bot100/show?bot_id=#{BOT_ID}"
     actions = [
                {
                  type: "uri",
                  label: "全ユーザーの投稿を見る",
                  uri: "https://ams1.n2bot.net/bot100/show?bot_id=#{BOT_ID}&user_event_id=#{user_event.id}"
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
    bot_id = BOT_ID
    user_event_id = params[:user_event_id]
    Rails.logger.debug("show bot_id=#{bot_id} user_event_id=#{user_event_id}")
    
    # 20個前のメッセージから表示開始
    last_ue = UserEvent.where(:bot_id => bot_id).order(:id => "desc").limit(20).last
    Rails.logger.debug("last_ue=#{last_ue.inspect}")
    @last_user_event_id =  last_ue.try(:id)
    @last_user_event_id = 0 if @last_user_event_id.blank?
  end
  
  # ajax 最新投稿をフェッチして返す
  def fetch()
    bot_id = BOT_ID
    @last_user_event_id = params[:last_user_event_id]
        
    @ues = UserEvent.find_by_sql(["select * from user_events where bot_id = ? AND id > ? order by id limit 10",
        bot_id, @last_user_event_id])
    
    if @ues.count > 0
      @last_user_event_id = @ues.last.try(:id)
    end
    
  end
end
