# 日本地図都道府県クイズ３択 ひらがな版 改良版
# 
class Bot22N2jpquiz3hirakaiController < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  
  BOT_ID = 22
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]
  
  # 都道府県
  PREF_CD_NAME = {
"01" => "ほっかいどう",
"02" => "あおもり",
"03" => "いわて",
"04" => "みやぎ",
"05" => "あきた",
"06" => "やまがた",
"07" => "ふくしま",
"08" => "いばらき",
"09" => "とちぎ",
"10" => "ぐんま",
"11" => "さいたま",
"12" => "ちば",
"13" => "とうきょう",
"14" => "かながわ",
"15" => "にいがた",
"16" => "とまや",
"17" => "いしかわ",
"18" => "ふくい",
"19" => "やまなし",
"20" => "ながの",
"21" => "ぎふ",
"22" => "しずおか",
"23" => "あいち",
"24" => "みえ",
"25" => "しが",
"26" => "きょうとふ",
"27" => "おおさかふ",
"28" => "ひょうご",
"29" => "なら",
"30" => "わかやま",
"31" => "とっとり",
"32" => "しまね",
"33" => "おかやま",
"34" => "ひろしま",
"35" => "やまぐち",
"36" => "とくしま",
"37" => "かがわ",
"38" => "えひめ",
"39" => "こうち",
"40" => "ふくおか",
"41" => "さが",
"42" => "ながさき",
"43" => "くまもと",
"44" => "おおいた",
"45" => "みやざき",
"46" => "かごしま",
"47" => "おきなわ",
  }

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "00a88e6a2d55e1dc062d1c15b48b99e9"
      config.channel_token = "UjMaQmWcKPq4TDYDX8EFFy3YtoiujTICbLU5ze7Dj0WqSdaFezIIjzsTQPuMkswm2YY0m3MiQkw7qRVDRnb558gLrsOOlwUx2dJekUEDfB1fA0hrI0c6DCH0AkzyzEvWWLHwaRxrf5Tq/OujNyKMOQdB04t89/1O/w1cDnyilFU="
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
      when Line::Bot::Event::Postback # 回答したので答え合わせ
        message = execute_answer_check(event)
        response = client.reply_message(event['replyToken'], message)
      end
    }
    
    Rails.logger.debug("response=#{response.try(:code)} #{response.try(:body)}")
  
    render text: ""
  end
  
  # 答え合わせ
  def execute_answer_check(event)
    # get user info
    mid = event['source']['userId']
    profile = get_profile(@client, mid)
    name = profile["displayName"]
    
    messages = []
    
    # 答え合わせ結果
    postback = event["postback"]
    data = eval(postback["data"])
    Rails.logger.debug("data = #{data.inspect}")
    action_pref = data[:action_pref]
    answer_pref = data[:answer_pref]
    
    if (action_pref == answer_pref)
      # 正解￼
      messages << {
            type: 'text',
            text: "⭕せいかい⭕
せいかいは「#{PREF_CD_NAME[answer_pref]} 」です。
#{name} さん すごい！！"
          }
    else
      # 不正解
      messages << {
            type: 'text',
            text: "❌まちがい❌
せいかいは「#{PREF_CD_NAME[answer_pref]} 」です。"
          }
    end
    
    # 次の問題作成
    answer_pref = sprintf("%02d", rand(47) + 1) # 01〜47
    messages << create_qa_img(answer_pref)
    messages << create_qa(answer_pref)
     
    # save
    # user_event = UserEvent.insert(BOT_ID, mid, event.to_json, profile.to_json) 

    # reply
    messages
  end
  
  # 新しく問題を発行
  def execute_start_map(event, follow_flg = false)
    # get user info
    mid = event['source']['userId']
    profile = get_profile(@client, mid)
    name = profile["displayName"]
    
    messages = []
    
    if follow_flg
      messages << {
            type: 'text',
            text: "#{name}さん 友だち登録ありがとうございます(happy)
「N2日本地図４択幼児向け」は、地図上の都道府県がどの県か４択で回答し続けるアカウントです。
是非末永くご利用ください。

本アカウントに関するお問合わせは
https://www.facebook.com/n2lab.inc/
にメッセージ送信でお願いします。􀀁"
          }
    end
    
    answer_pref = sprintf("%02d", rand(47) + 1) # 01〜47
    messages << create_qa_img(answer_pref)
    messages << create_qa(answer_pref)
     
    # save
    # user_event = UserEvent.insert(BOT_ID, mid, event.to_json, profile.to_json) 

    # reply
    messages
  end
  
  # 問題の画像を配信
  def create_qa_img(answer_pref)
    url = "https://img.n2bot.net/bot19/pref/pref#{answer_pref}.png"
    {
      type: "image",
      originalContentUrl: url,
      previewImageUrl: url
    }
  end
  
  def get_dummy_answer(answer_pref, del_pref = nil)
    dummy = [*1..47]
    dummy.delete(answer_pref.to_i)
    dummy.delete(del_pref.to_i) unless del_pref.blank?
    sprintf("%02d", dummy.sample)
  end
  
  # 問題の回答選択肢を作成
  # ボタン式テンプレートメッセージにする
  def create_qa(answer_pref)
    # dummy_pref1 = get_dummy_answer(answer_pref)
    # ダミー回答１は近い県にする
    dummy_pref1 = sprintf("%02d", (answer_pref.to_i + 1) % 47 + 1)
    dummy_pref2 = get_dummy_answer(answer_pref, dummy_pref1)
    dummy_pref3 = get_dummy_answer(answer_pref, dummy_pref1, dummy_pref2)

    title = "ここはなにけん？"
    text = "ここはなにけん"
    actions = [
                {
                    type: "postback",
                    label: PREF_CD_NAME[answer_pref],
                    data: {:action_pref => answer_pref, :answer_pref => answer_pref}.to_s
                },
                {
                    type: "postback",
                    label: PREF_CD_NAME[dummy_pref1],
                    data: {:action_pref => dummy_pref1, :answer_pref => answer_pref}.to_s
                },
                {
                    type: "postback",
                    label: PREF_CD_NAME[dummy_pref2],
                    data: {:action_pref => dummy_pref2, :answer_pref => answer_pref}.to_s
                },
                {
                    type: "postback",
                    label: PREF_CD_NAME[dummy_pref3],
                    data: {:action_pref => dummy_pref3, :answer_pref => answer_pref}.to_s
                },
      ].shuffle
    
      {
        type: "template",
        altText: text,
        template: {
            type: "buttons",
            text: text,
            actions: actions
        }
      }      
    
  end
  

end
