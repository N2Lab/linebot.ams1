# キーワードからネタ画像を返す ランダム画像を返す bot
# 画像メッセージで返す
class Bot12N2imgmsgsearchsimpleController < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  
  BOT_ID = 12
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "024416f8a75d1158bf494ef16997eb82"
      config.channel_token = "x0nxAPZWr3M2wSgQvwk6/Dhz2ZKKy3HQZrlnMMB7MgXqd0DoFZABrjuj86g8ELsyKnJbxqGc8GEH6vbjai6IcXDiuugCWxu22Dj+REwtR/8D+qcqvx3+O2CA2f1JrEMlo6WFv1a8k0riwb054M3BAQdB04t89/1O/w1cDnyilFU="
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
          message = execute_text_event(event)
          response = client.reply_message(event['replyToken'], message)
          # 下記はプロプランのみ
          # Resque.enqueue(SendTextWorker, client.channel_secret, client.channel_token, event.message['id'], "worker")
          
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      when Line::Bot::Event::Postback # 他の画像
        response = client.reply_message(event['replyToken'], execute_postback_event(event))
      when Line::Bot::Event::Join # グループ・ルーム追加
        response = client.reply_message(event['replyToken'], on_join_grp(event))
      when Line::Bot::Event::Leave # グループ・ルーム退出
      end
    }
    
    Rails.logger.debug("response=#{response.try(:code)} #{response.try(:body)}")
  
    render text: "OK"
  end
  
  # グループ参加時
  # 適当にメッセージを返すで良い
  def on_join_grp(event)
    msg = "招待ありがとう！
N2ネタ画像Sbot アカウントは、何かメッセージを送信すると、そのメッセージでネタ画像を検索して返すアカウントです！
グループ・ルームトークでも利用可能です。
是非末永くご利用ください。

本アカウントに関するお問合わせは
https://www.facebook.com/n2lab.inc/
にメッセージ送信でお願いします！"
    [
      {
        type: 'text',
        text: msg
      }
    ]
  end
  
  # グループ退出時
  def on_leave_grp(event)
    
  end

  def execute_text_event(event)
    text = event.message['text']
    execute_text(text)
  end

  def execute_postback_event(event)
    postback = event["postback"]
    # Rails.logger.debug("postback = #{postback.inspect}")
    # Rails.logger.debug("postback.class = #{postback.class}")
    # postback = {"data"=>"{:next_no=>\"1\", :ymdh=>\"2016102307\"}"}
    
    data = eval(postback["data"])
    Rails.logger.debug("data = #{data.inspect}")
    text = data[:query]
    page = data[:page]
    execute_text(text, page)
  end
  
  # メインロジック (テキストメッセージ)にカルーセルで返す
  def execute_text(text, page = 0)

    # find images
    image_list = find_image_list(text)
    img = image_list.sample
    
    # イメージメッセージで返す
    image_url = "https://img.tiqav.com/#{img["id"]}.#{img["ext"]}"
    [{
      type: "image",
      originalContentUrl: image_url,
      previewImageUrl: image_url
      }
    ]
  end
  
  def get_random_image_list()
    # 1. http://api.tiqav.com/search/random.json
    # 2. http://img.tiqav.com/[id].[ext] で画像をテンプレートメッセージで返して次の画像へ

    uri = URI.parse('http://api.tiqav.com/search/random.json')
    json = Net::HTTP.get(uri)
    JSON.parse(json)
  end
  
  def find_image_list(query)
    # 1. http://api.tiqav.com/search.json?q=[query]&callback=[fucntion_name]
    # 2. http://img.tiqav.com/[id].[ext] で画像をテンプレートメッセージで返して次の画像へ

    uri = URI.parse("http://api.tiqav.com/search.json?q=#{URI.escape(query)}")
    json = Net::HTTP.get(uri)
    JSON.parse(json)
  end
  
end
