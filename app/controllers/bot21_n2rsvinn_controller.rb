# N2宿泊予約デモ
# プッシュ配信不可版
#
class Bot21N2rsvinnController < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  require 'RMagick' 
  include Magick
  
  BOT_ID = 21
  
  # おかみ画像
  OKAMI_URL = "https://img.n2bot.net/bot21/okami.png"
  
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]

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
        response = client.reply_message(event['replyToken'], execute_postback(event))
      end
    }
    
    Rails.logger.debug("response=#{response.try(:code)} #{response.try(:body)}")
  
    render text: ""
  end
  
  # メインメニュー応答
  # 1. 予約したい
  # 2. 予約内容を確認したい
  # 3. 宿の情報,行き方を知りたい
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
                    label: "宿の情報・行き方を知りたい",
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
  
  # アクション選択時応答
  def execute_postback(event)
    # get user info
    mid = event['source']['userId']
#    profile = get_profile(@client, mid)
#    name = profile["displayName"]

    postback = event["postback"]
    
    data = eval(postback["data"])
    Rails.logger.debug("data = #{data.inspect}")
    menu = data[:menu] # メニュー
    sel = data[:sel] # 選択した選択肢
    
    # メソッド作成
    method = "postback_#{menu}_#{sel}"
    send(method, event)
    
  end
  
  ################################################
  # 予約したい 
  ################################################
  
  # 希望日選択イメージマップ用画像を返す
  def cal_img()
    year = params[:year]
    month = params[:month]
    size = params[:size]
    
    # とりあえず固定画像を返す
    w = 1040
    h = 1040
    image = Image.new(w, h)
    image.format = "PNG"
    
    # draw month (title)
    
    # draw days
    draw = Draw.new
    draw.pointsize = 32
    draw.gravity = CenterGravity
    
    block_w = 1040 / 7
    (1..31).each do |d|
      x = block_w * ((d - 1) % 7)
      y = block_w * (d / 7)
      draw.annotate(image, x, y, block_w, block_w, d.to_s)
    end
    # 将来はs3管理か (CF> origin:Ec2)
    
    send_data(image.to_blob)
#   send_data(image.to_blob, :type => 'image/png', :disposition=>'inline')
  end
  
  # 1-1 予約したい メニュー
  # 希望日選択カレンダー (将来的に空室カレンダー)
  def postback_1_1(event)
    # get user info
    mid = event['source']['userId']
    profile = get_profile(@client, mid)
    name = profile["displayName"]
    
    # imagemapの場合
    image_url = "https://ams1.n2bot.net/bot21_n2rsvinn/imagemap/cal/2016/11/#{Time.now.to_i}"
    {
      "type": "imagemap",
      "baseUrl": image_url,
      "altText": "予約カレンダー",
      "baseSize": {
          "height": 1040,
          "width": 1040
      },
      "actions": [
          {
              "type": "message",
              "text": "1_1_20161112",
              "area": {
                  "x": 0,
                  "y": 0,
                  "width": 520,
                  "height": 1040
              }
          },
          {
              "type": "message",
              "text": "1_1_20161112",
              "area": {
                  "x": 520,
                  "y": 0,
                  "width": 520,
                  "height": 1040
              }
          }
      ]
    }    
    
    # template(button)の場合
    # # 予約方法選ぶ
    # title "- 予約したい - "
    # text = "#{name}様のご希望宿泊日は何月でしょうか？"
    # actions = [
                # {
                    # type: "postback",
                    # label: "前月へ",
                    # data: {:menu => "1a", :sel => 0, :ym => "201609"}.to_s
                # },
                # {
                    # type: "postback",
                    # label: "11月",
                    # data: {:menu => "1a", :sel => 0, :ym => "201609"}.to_s
                # },
                # {
                    # type: "postback",
                    # label: "12月",
                    # data: {:menu => "1a", :sel => 0, :ym => "201609"}.to_s
                # },
                # {
                    # type: "postback",
                    # label: "次月へ",
                    # data: {:menu => "1a", :sel => 0, :ym => "201609"}.to_s
                # },
      # ]
#     
      # make_template_buttons_message(title, text, url, actions)
  end
  
  # 1a-N 予約したい   > 宿泊日選択
  def postback_1a_0(event)
    # get user info
    mid = event['source']['userId']
    profile = get_profile(@client, mid)
    name = profile["displayName"]
    
    # 予約方法選ぶ
    title "- 予約したい - "
    text = "#{name}様のご希望宿泊日は何日でしょうか？"
    actions = [
                {
                    type: "postback",
                    label: "前月へ",
                    data: {:menu => "1a", :sel => 0, :ym => "201609"}.to_s
                },
                {
                    type: "postback",
                    label: "11月",
                    data: {:menu => "1a", :sel => 0, :ym => "201609"}.to_s
                },
                {
                    type: "postback",
                    label: "12月",
                    data: {:menu => "1a", :sel => 0, :ym => "201609"}.to_s
                },
                {
                    type: "postback",
                    label: "次月へ",
                    data: {:menu => "1a", :sel => 0, :ym => "201609"}.to_s
                },
      ]
    
      make_template_buttons_message(title, text, url, actions)
  end
end
