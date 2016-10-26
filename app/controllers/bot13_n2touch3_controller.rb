# ３択メッセージで1〜10まで選択したスピードでスコアを競う
class Bot13N2touch3Controller < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  
  BOT_ID = 13
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "7490b144f888f88062a0d5f59c0bf71b"
      config.channel_token = "Ttuxg1fPesyTTlc4oOhpRSM2fwNpH+KvYJVvWyS+zqmaACqHL+ZCM3OPp/oq4kU4h8dtg7xb/HEvNCQUjeROINqFoVXlZghnaiVFQ7dQCH2QCv4SzZWjXLyIuehFiotrLXdUIXi/dP2RrFbGQZ8kXgdB04t89/1O/w1cDnyilFU="
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
          message = execute_new_play(event)
          response = client.reply_message(event['replyToken'], message)
          
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      when Line::Bot::Event::Postback # 他の画像
        response = client.reply_message(event['replyToken'], execute_postback(event))
      end
    }
    
    Rails.logger.debug("response=#{response.try(:code)} #{response.try(:body)}")
  
    render text: "OK"
  end
  
  # 新規プレイ開始
  def execute_new_play(event)
    # 次の正解を保存＆プレイ開始
#    start_at = DateTime.now.strftime("%Y/%m/%d %H:%M:%S")
    start_at = Time.now.to_f.to_s
    Attr.save(BOT_ID, event['source']['userId'], 1, 1, start_at) # 現在の数字
    Attr.save(BOT_ID, event['source']['userId'], 2, 0, start_at) # 開始時間
    send_selector_by_next_no(event, 1, "プレイ開始！１から１０まで順番に選択してください！")
  end
  
  # 次の選択肢を配信
  # next_no=次の正解
  def send_selector_by_next_no(event, next_no, text)
    actions = [
                {
                  type: "postback",
                  label: next_no,
                  data: {:no => next_no}.to_s
                },
                {
                  type: "postback",
                  label: next_no - 1,
                  data: {:no => next_no - 1}.to_s
                },
                {
                  type: "postback",
                  label: next_no + 1,
                  data: {:no => next_no + 1}.to_s
                }
    ].shuffle
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
  
  # 答え合わせ
  def execute_postback(event)
    # 正解取得 attr.val
    mid = event['source']['userId']
    attr = Attr.get(BOT_ID, mid, 1)
    
    # ユーザーの選択値
    postback = event["postback"]
    data = eval(postback["data"])
    Rails.logger.debug("data = #{data.inspect}")
    user_no = data[:no]
    if user_no.to_i == -1
      return execute_new_play(event)
    end
    
    if user_no.to_i == attr.val.to_i
      # 一致したので次へ
      if (attr.val.to_i == 10) 
        # 全問終了 結果表示へ
        return on_finish(event)
      else
        # 正解, + 1 して次へ
        next_no = attr.val.to_i + 1
        Attr.save(BOT_ID, mid, 1, next_no, "")
        send_selector_by_next_no(event, next_no, "⭕ 正解！　次は？")
      end
    else
      # 不一致は再送信
      send_selector_by_next_no(event, attr.val, "❎ 残念！　もう一度選んでね")
    end
    
  end
 
  # 全問終了時
  def on_finish(event)
    mid = event['source']['userId']
    # プレイ時間計算
    attr = Attr.get(BOT_ID, mid, 2)
    #プレイ開始時間
#    start_at = DateTime.parse(attr.text)
    start_at = attr.text.to_f
# 秒の場合    ((DateTime.now - start_at) * 24 * 60 * 60).to_i
    # スコアの差を出すため1/100秒=1点とする
    
    secs = (Time.now.to_f - start_at).to_i
    score = (10000.0 / (Time.now.to_f - start_at)).to_i
    
    # get profile
    profile = get_profile(@client, mid)
    name = profile["displayName"]
    
    # get best
    ymd = DateTime.now.strftime("%Y%m%d")
    best_id = 10
    best = Attr.get(BOT_ID, ymd, best_id)
    get_best_msg = ""
    if best.blank?
      # 自分をベストスコアとして保存
      best = Attr.save(BOT_ID, ymd, best_id, score, name)
      get_best_msg = "おめでとう！本日のベストスコアです！"
    else
      # 自分のスコアが上なら更新
      if best.val <= score
        best = Attr.save(BOT_ID, ymd, best_id, score, name)
        get_best_msg = "おめでとう！本日のベストスコアです！"
      end
    end
    best_name = best.text
    best_score = best.val
        
    # 
    text = "⭕ すべて正解！　お疲れ様です。
#{get_best_msg}
#{name}さんのスコア 【#{score}】点
かかった時間　　【#{secs}】秒

本日のベストスコア 
#{best_name}【#{best_score}】点
"
     actions = [
                {
                  type: "postback",
                  label: "再プレイ",
                  data: {:no => -1}.to_s
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
    
end
