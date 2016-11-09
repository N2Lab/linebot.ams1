# 日本地図都道府県クイズ３択
# 
class Bot19N2jpquiz3Controller < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  
  BOT_ID = 19
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]
  
  # 都道府県
  PREF_CD_NAME = {
"01" => "北海道",
"02" => "青森県",
"03" => "岩手県",
"04" => "宮城県",
"05" => "秋田県",
"06" => "山形県",
"07" => "福島県",
"08" => "茨城県",
"09" => "栃木県",
"10" => "群馬県",
"11" => "埼玉県",
"12" => "千葉県",
"13" => "東京都",
"14" => "神奈川県",
"15" => "新潟県",
"16" => "富山県",
"17" => "石川県",
"18" => "福井県",
"19" => "山梨県",
"20" => "長野県",
"21" => "岐阜県",
"22" => "静岡県",
"23" => "愛知県",
"24" => "三重県",
"25" => "滋賀県",
"26" => "京都府",
"27" => "大阪府",
"28" => "兵庫県",
"29" => "奈良県",
"30" => "和歌山県",
"31" => "鳥取県",
"32" => "島根県",
"33" => "岡山県",
"34" => "広島県",
"35" => "山口県",
"36" => "徳島県",
"37" => "香川県",
"38" => "愛媛県",
"39" => "高知県",
"40" => "福岡県",
"41" => "佐賀県",
"42" => "長崎県",
"43" => "熊本県",
"44" => "大分県",
"45" => "宮崎県",
"46" => "鹿児島県",
"47" => "沖縄県",
  }

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "b3ff1a1f5b22d6096a54148acdc575fc"
      config.channel_token = "EksKcc1u+F62Fr1sVhXvT2UV7K1UZG18JNhu9CzTh9HVkuUrZNdaVDdiDFPaEnwRZHNdQvuZnc7naIn20pCb1jcnn/LGZy3ahpm2DGiHs5BWuzCSkB5pPtMSQjtVIwgKTtusy+ycP1AGGNSW1puDAwdB04t89/1O/w1cDnyilFU="
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
            text: "⭕正解⭕
#{name} さんさすが！！"
          }
    else
      # 不正解
      messages << {
            type: 'text',
            text: "❌不正解❌
正解は「#{PREF_CD_NAME[answer_pref]} 」です。"
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
#    profile = get_profile(@client, mid)
    
    messages = []
    
    if follow_flg
      messages << {
            type: 'text',
            text: "友だち登録ありがとうございます(happy)
N2日本地図３択は、地図上の都道府県がどの県か３択で回答し続けるアカウントです。
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
  def create_qa(answer_pref)
    # dummy_pref1 = get_dummy_answer(answer_pref)
    # ダミー回答１は近い県にする
    dummy_pref1 = sprintf("%02d", (answer_pref.to_i + 1) % 47 + 1)
    dummy_pref2 = get_dummy_answer(answer_pref, dummy_pref1)

    text = "ここは何県（なにけん）？"
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
    ].shuffle
    
      {
        type: "template",
        altText: text,
        template: {
            type: "confirm",
            text: text,
            actions: actions
        }
      }      
    
  end
  

end
