class Bot8N2asiatoController < ApplicationController

  require 'line/bot'
  
  BOT_ID = 8
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "c6231076da09bd465c21888c664b30e2"
      config.channel_token = "7hHQLk20bW3MP0Fd8ieYF2UwAwfJBQSi7hnxv65q2YkxaYeH17ETeEAoM6XrSdsMI6gFrjcIVeFR15EwMhT5e4ax9RtxyXjejT8xEMzXeayT6XqBiiIsDrlGMsQa8m2ebfaNsKHaIt3Wf2SmXnY22AdB04t89/1O/w1cDnyilFU="
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

  # メインロジック (テキストメッセージ)
  def execute(event)
    text = event.message['text']
    
    # 以前のメッセージを取得
    attr = Attr.get(BOT_ID, "last_msg", 1)
    
    msg = attr.blank? ? "最初のメッセージありがとうございます!" : attr.text
    
    # 受信メッセージを保存
    Attr.save(BOT_ID, "last_msg", 1, 0, text)
    
    [{
      type: 'text',
      text: msg
    }]
  end
end
