class Bot7N2matomeController < RssapiController

  require 'line/bot'
  
  BOT_ID = 7
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "06d46b346b6ed12b22989ca164850550"
      config.channel_token = "+waCDJng8EOGfXusYtpOIT8ZlwBS0eN71w1Pn0y80TXY714wqmoHSHoaBK28cgjB6Jk5aODfBEY8p7HRxQa2DD5mDpM2zRK0XkzItR7jnCCWq45wcgrf1TYdRSc6H1fNvpfPkuuserPmJ9fFjxh6EwdB04t89/1O/w1cDnyilFU="
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
          message = execute(event)
          client.reply_message(event['replyToken'], message)
          # 下記はプロプランのみ
          # Resque.enqueue(SendTextWorker, client.channel_secret, client.channel_token, event.message['id'], "worker")
          
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      when Line::Bot::Event::Postback # 次へ など選択
        client.reply_message(event['replyToken'], execute_for_postback_event(event))
      end
    }
  
    render text: "OK"
  end

  
  # メインロジック (postback)
  # ユーザーのアクションに応じて記事を配信
  def execute_for_postback_event(event)
    postback = event["postback"]
    
    data = eval(postback["data"])
    Rails.logger.debug("data = #{data.inspect}")
    next_no = data[:next_no].to_i
    
    send_news_by_next_no(event, next_no)
  end
  
  # メインロジック (テキストメッセージ)
  def execute(event)
    #状態によって分岐
    text = event.message['text']
    
    if (MENUS.include?(text))
      # 何もしない
      return []
#      return send_next_news(event)
    else
      # 作成へ
      return send_today_top_news(event)
    end
  end
  
  # 1. 現在時のニュースがなければ作成
  # 2. 配信する
  def send_today_top_news(event)
    ymdh = DateTime.now.strftime("%Y%m%d%H")
    attr = Attr.get(BOT_ID, ymdh, 1)
    create_news(ymdh) if attr.blank?

    # 先頭を配信
    send_next_news(event)
  end
  
  #  現在日時の指定noのニュースを配信
  # last_no = 最終配信no
  def send_news_by_next_no(event, next_no)
    send_news_by_botid_nextno(BOT_ID, event, next_no)
  end
  
  # 現在日時の次のニュースを配信
  def send_next_news(event)
    current_no = -1 # 初期値
    next_no = current_no + 1

    send_news_by_next_no(event, next_no)
  end
  
  # 現在時でニュース作成
  def create_news(ymdh)
    create_news_by_bot_id(BOT_ID, ymdh)
  end
end
