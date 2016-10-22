class Bot1FlashanzanController < ApiController

  require 'line/bot'
  require 'resque'

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
    BOT1_MENUS = [
      "初級", "中級", "上級", "鬼"
    ]
  
  # メインロジック
  def execute(event)
    #状態によって分岐
    text = event.message['text']
    
    if (BOT1_MENUS.include?(text))
      # 新規問題配信
      return create_qa(event)
    else
      # 答え合わせ
      return check_answer(event)
    end
  end
  
  # 問題新規作成配信
  def create_qa(event)
    text = event.message['text']
    qtype = BOT1_MENUS.index(text)
    # 問題数
    qnums = [3, 5, 10, 10]
    # 桁数 (出題範囲)
    ketas = [[*1..9], [*1..9], [*1..9], [*1..99]]
    
    #問題作成
    qas = []
    qnums[qtype].times do|index|
      qas << ketas[qtype].sample
    end
    
    # 問題を保存
    Attr.save(1, event['source']['userId'], 1, qas.sum, qas.to_s)
    
    #配信メッセージ作成
    return [
          {
            type: 'text',
            text: "#{text}の問題です。5秒以内に回答してください。"
          },
          {
            type: 'text',
            text: qas.join("\n")
          }
    ]
  end
  
  # 答え合わせ
  def check_answer(event)
    
    attr = Attr.get(1, event['source']['userId'], 1)
    
    return [{
            type: 'text',
            text: "<<遊び方>>
            リッチメニューから問題レベルを選んでください。
            数字返信されるので合計を計算して入力してください。"
          }] if attr.blank?

    text = event.message['text']
    
    # 回答までの秒数 (xx.x sec)
    qa_sec = (Time.now - attr.updated_at).round(1)
    
    # 時間に応じて IQかあなたのレベルを返す TODO 総合的に文言を決定する TODO 絵文字も使う
    label_name = "天才"
    
    # 正解かどうかを説明
    input_answer = text.tr('０-９ａ-ｚＡ-Ｚ', '0-9a-zA-Z')
    
    result_label = "おめでとう！正解です"
    if input_answer.to_i == attr.val
      # 正解！
      # 時間毎にメッセージを変える
      if qa_sec < 2.0
        result_label = "正解#￼￼￼！速い！素晴らしい！"
      elsif qa_sec < 4.0
        result_label = "正解！速い！"
      elsif qa_sec <= 5.0 # 
        result_label = "正解！おめでとう！"
      elsif qa_sec <= 10.0 #
        result_label = "正解"
      else 
        result_label = "正解！"
      end
      # TODO 正解までの時間でメッセージを分岐する
    else
      # 不正解
      result_label = "残念 不正解です"
    end
    
    msg = "#{[ 0x10006C ].pack( "U*" )}「　#{result_label}　」
    あなたの答え #{input_answer}
    問題の答え #{attr.val}
    あなたの計算力 #{label_name}
    回答時間 #{qa_sec}秒"
    
    attr.delete
    return [
          {
            type: 'text',
            text: msg
          }
    ]
  end

end
