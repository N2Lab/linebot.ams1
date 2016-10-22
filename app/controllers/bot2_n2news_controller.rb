class Bot2N2newsController < ApiController

  require 'line/bot'

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "56b72092ab5d4c481a3850e607e341c2"
      config.channel_token = "W63xDhQ6d9C537L3TX0iJQ8izawS9SDYF08Z1bbVNqCCGpbvEf2N7LCrHjbgET3L3zUL0CHja3vOX7bMfOfWzGJN2eKit4K7AsattXw3VmczPHi3HU92kHtTNEZa7Hk07r0iyj0DYhpoeH1icj1FBQdB04t89/1O/w1cDnyilFU="
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
      end
    }

  
    render text: "OK"
  end

    # リッチメニュー選択肢
    BOT2_MENUS = ["今日のニュース", "次へ"]
  
  # メインロジック
  def execute(event)
    #状態によって分岐
    text = event.message['text']
    
    if (BOT2_MENUS.include?(text))
      # 次の記事へ
      return send_next_news(event)
    else
      # 作成へ
      return send_today_top_news(event)
    end
  end
  
  # 1. 現在時のニュースがなければ作成
  # 2. 配信する
  def send_today_top_news(event)
    ymdh = DateTime.now.strftime("%Y%m%d%H")
    attr = Attr.get(2, ymdh, 1)
    create_news(ymdh) if attr.blank?

    # 先頭を配信
    send_next_news(event)
  end
  
  # 現在日時の次のニュースを配信
  def send_next_news(event)
    
    # TODO 番号は仮
    
    current_no = -1
    next_no = current_no + 1
    ymdh = DateTime.now.strftime("%Y%m%d%H")
    
    attr = Attr.get(2, ymdh, 1)
    send_feed_all = eval(attr.text) # 送信対象 TODO 最後チェック
    
    send_feed = send_feed_all[next_no]
    
    Rails.logger.debug("send_feed=#{send_feed.inspect}")
    
    # 送信実行 仮
    return [
      # プレビュー表示されるためのURL配信
      {
            type: 'text',
            text: "コメント1"
      },
      {
            type: 'text',
            text: "コメント2"
      },
      {
            type: 'text',
            text: "コメント3"
      },
      {
            type: 'text',
            text: "コメント4"
      },
      # 操作配信 TODO 引用元
      {
        "type": "template",
        "altText": send_feed[:title],
        "template": {
            "type": "confirm",
            "text": send_feed[:title],
            "actions": [
                {
                  "type": "postback",
                  "label": "前へ",
                  "text": "前へ",
                  "data": (next_no-1).to_s
                },
                {
                  "type": "uri",
                  "label": "読む",
                  "uri": send_feed[:link]
                },
                {
                  "type": "postback",
                  "label": "次へ",
                  "text": "次へ",
                  "data": (next_no+1).to_s
                }
            ]
        }
      }
    ]
    
  end
  
  # 現在時でニュース作成
  def create_news(ymdh)
    
    # news array
    news = NewsFeed.get_news_hash_array()
    
    # ニュース作成保存
    Attr.save(2, ymdh, 1, 0, news.to_s)
  end
  

end
