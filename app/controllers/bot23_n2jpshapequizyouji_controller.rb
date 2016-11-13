# N2 都道府県形クイズ4択 幼児向け
# 
class Bot23N2jpshapequizyoujiController < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  
  BOT_ID = 23
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]
  
  # 都道府県
  PREF_CD_NAME = {
"01" => "ほっかいどう",
"02" => "あおもりけん",
"03" => "いわてけん",
"04" => "みやぎけん",
"05" => "あきたけん",
"06" => "やまがたけん",
"07" => "ふくしまけん",
"08" => "いばらきけん",
"09" => "とちぎけん",
"10" => "ぐんまけん",
"11" => "さいたまけん",
"12" => "ちばけん",
"13" => "とうきょうと",
"14" => "かながわけん",
"15" => "にいがたけん",
"16" => "とまやけん",
"17" => "いしかわけん",
"18" => "ふくいけん",
"19" => "やまなしけん",
"20" => "ながのけん",
"21" => "ぎふけん",
"22" => "しずおかけん",
"23" => "あいちけん",
"24" => "みえけん",
"25" => "しがけん",
"26" => "きょうとふ",
"27" => "おおさかふ",
"28" => "ひょうごけん",
"29" => "ならけん",
"30" => "わかやまけん",
"31" => "とっとりけん",
"32" => "しまねけん",
"33" => "おかやまけん",
"34" => "ひろしまけん",
"35" => "やまぐちけん",
"36" => "とくしまけん",
"37" => "かがわけん",
"38" => "えひめけん",
"39" => "こうちけん",
"40" => "ふくおかけん",
"41" => "さがけん",
"42" => "ながさきけん",
"43" => "くまもとけん",
"44" => "おおいたけん",
"45" => "みやざきけん",
"46" => "かごしまけん",
"47" => "おきなわけん",
  }

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "c57f91c673c208e3c0cffb114dbe29bc"
      config.channel_token = "e77WtsBT1i+vTxizGp66CdFXtAbKF3XathiTgrG8U2YJFBpjp28xbMjiDs5BVr0mmb6UAs6PhA6o7q7Rbsl74nrsjU+6W9XbyCTvN76YkoTs+TQyEmtvatdPFkjsWZ9GPjnGA6fEwSClAO4omaGRdwdB04t89/1O/w1cDnyilFU="
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
    messages = []
    
    # 答え合わせ結果
    postback = event["postback"]
    data = eval(postback["data"])
    Rails.logger.debug("data = #{data.inspect}")
    action_pref = data[:action_pref]
    answer_pref = data[:answer_pref]
    
    if action_pref.to_i == -1
      # 次の問題を作成して返す
      answer_pref = sprintf("%02d", rand(47) + 1) # 01〜47
      messages << create_qa_img(answer_pref)
      messages << create_qa(answer_pref)
      return messages     
    end
    
    
    # get user info
    mid = event['source']['userId']
    profile = get_profile(@client, mid)
    name = profile["displayName"]
    
    
    
    if (action_pref == answer_pref)
      # 正解￼
      messages << {
            type: 'text',
            text: "􀀄せいかい􀀄
せいかいは
「#{PREF_CD_NAME[answer_pref]} 」
です。#{name} さん すごい！！"
          }
    else
      # 不正解
      messages << {
            type: 'text',
            text: "￼￼􀄃􀄛astonished􏿿まちがい
せいかいは
「#{PREF_CD_NAME[answer_pref]} 」
です。"
          }
    end
    
    # 次の問題作成 > ここではやらない
    # answer_pref = sprintf("%02d", rand(47) + 1) # 01〜47
    # messages << create_qa_img(answer_pref)
    # messages << create_qa(answer_pref)
    
    # つぎのもんだいへ
    messages << create_next_qa_link()
     
 
    # reply
    messages
  end
  
  # 次の問題へのリンクを表示
  def create_next_qa_link()
    text = "もういっかいちょうせんする？"
    actions = [
                {
                    type: "postback",
                    label: "ちょうせんする",
                    data: {:action_pref => -1}.to_s
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
            text: "#{name}さん 友だち登録ありがとうございます!
「N2都道府県形クイズ4択 幼児向け」は、都道府県の形からどの都道府県か４択で回答し続けるアカウントです。
是非末永くご利用ください。

本アカウントに関するお問合わせは
https://www.facebook.com/n2lab.inc/
にメッセージ送信でお願いします。􀀁"
          }
    end
    
    # 問題作成
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
    url = "https://img.n2bot.net/bot23/#{answer_pref}.png"
    {
      type: "image",
      originalContentUrl: url,
      previewImageUrl: url
    }
  end
  
  def get_dummy_answer(answer_pref, del_pref = nil, del_pref2 = nil)
    dummy = [*1..47]
    dummy.delete(answer_pref.to_i)
    dummy.delete(del_pref.to_i) unless del_pref.blank?
    dummy.delete(del_pref2.to_i) unless del_pref2.blank?
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
    text = "ここはなにけん？"
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
