# N2宿泊予約デモ
# プッシュ配信不可版
#
class Bot21N2rsvinnController < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  
  BOT_ID = 21
  
  # おかみ画像
  OKAMI_URL = "https://img.n2bot.net/bot21/okami.png"
  
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
      config.channel_secret = "10043ddc7163b3d1dbbb262d385c42cb"
      config.channel_token = "jdBjCF0TtcEAKO9iKvLLUN9sdjMgbe8Wc4QtclQdeJ9kQQPVjKFp7OFyQUT+mQWJOJaamFvtNCTzriEnJXARBfMPCfEfyngeqoSrlSILQ1tBz2P8X2BqO1dMB7q7B2PVncHfdpKuVR+OZC4HgnC0OwdB04t89/1O/w1cDnyilFU="
    }
  end

  # bot endpoint
  # 
  # 友だち追加時, 何かメッセージを貰ったとき, リッチメニューで「メニュー」を選択→メインメニュー表示
  # メインメニューの各postbackアクションを選択 or リッチメニューのアクションを選択 →各機能へ あとは postback と各種メッセージだけで解決させる
  # AIは対応しない
  #
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
          response = client.reply_message(event['replyToken'], execute_main_menu(event))
        
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          case event.message['text']
          when "メニュー" # メインメニュー応答
            response = client.reply_message(event['replyToken'], execute_main_menu(event))
          else # それ以外も仮でメインメニュー応答 TODO イメージマップの何か選択時の可能性あり 後で対応
            response = client.reply_message(event['replyToken'], execute_main_menu(event))
          end
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.reply_message(event['replyToken'], execute_main_menu(event))
        end
      when Line::Bot::Event::Postback # 各種コマンド
        # message = execute_answer_check(event)
        # response = client.reply_message(event['replyToken'], message)
      end
    }
    
    Rails.logger.debug("response=#{response.try(:code)} #{response.try(:body)}")
  
    render text: ""
  end
  
  # メインメニュー応答
  # 1. 予約したい
  # 2. 予約内容を確認したい
  # 3. 宿の情報を知りたい
  # 4. 問い合わせしたい
  def execute_main_menu(event)
    # get user info
    mid = event['source']['userId']
    profile = get_profile(@client, mid)
    name = profile["displayName"]
    
    messages = []
    
    text = "旅館「◯◯」でございます。
どのようなご要件でしょうか？"
     actions = [
                {
                    type: "postback",
                    label: "予約したい",
                    data: {:menu => 1, :sel => 1}.to_s
                },
                {
                    type: "postback",
                    label: "予約内容を確認したい",
                    data: {:menu => 1, :sel => 2}.to_s
                },
                {
                    type: "postback",
                    label: "宿の情報を知りたい",
                    data: {:menu => 1, :sel => 3}.to_s
                },
                {
                    type: "postback",
                    label: "問い合わせしたい",
                    data: {:menu => 1, :sel => 4}.to_s
                },
      ]
    
      {
        type: "template",
        altText: text,
        template: {
            type: "buttons",
            thumbnailImageUrl: OKAMI_URL,
            title: "お問い合わせありがとうございます。",
            text: text,
            actions: actions
        }
      }   
  end
  

end
