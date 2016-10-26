# キーワードからネタ画像を返す ランダム画像を返す bot
# 1. http://api.tiqav.com/search/random.json
# 2. http://img.tiqav.com/[id].[ext] で画像をテンプレートメッセージで返して次の画像へ
class Bot11N2imgmsgsearchController < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  
  BOT_ID = 11
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "691699982b754444f86c71faabb46dcf"
      config.channel_token = "kgxB0T459Fx8cSQtVRZrfcAu9FhtzrBy0WGk0gW+lrePDkYqc13Zd0fynNQOcUjU+FEh7fTiiFj0EXzW+Zt1eXleO+yrhkFwZnP2U1gfHHf/s75shDPoBMHh9YZTAKILSCn5Hz/jFTxterflBYNXqAdB04t89/1O/w1cDnyilFU="
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
N2ネタ画像検索アカウントは、何かメッセージを送信すると、そのメッセージでネタ画像を検索して返すアカウントです！
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
  end

  def execute_postback_event(event)
    postback = event["postback"]
    # Rails.logger.debug("postback = #{postback.inspect}")
    # Rails.logger.debug("postback.class = #{postback.class}")
    # postback = {"data"=>"{:next_no=>\"1\", :ymdh=>\"2016102307\"}"}
    
    data = eval(postback["data"])
    Rails.logger.debug("data = #{data.inspect}")
    text = data[:query]
    
    execute_text(text)
  end
  
  # メインロジック (テキストメッセージ)にカルーセルで返す
  def execute_text(text)

    # find images
    image_list = find_image_list(text)
    # [{"id":"5AX","ext":"jpg","height":219,"width":333,"source_url":"http://mar.2chan.net/jun/b/src/1343375952522.jpg"},
      # {"id":"sg","ext":"jpg","height":531,"width":419,"source_url":"http://feb.2chan.net/jun/b/src/1258964461577.jpg"},
    
    # テンプレートメッセージのカルーセルで返す
    columns = []
    
    image_list[0,5].each do |img|
      image_url = "https://img.tiqav.com/#{img["id"]}.#{img["ext"]}"
      Rails.logger.debug("add image_url=#{image_url}")
      columns << {
            thumbnailImageUrl: image_url,
            title: "おすすめネタ画像です！",
            text: image_url,
            actions: [
                {
                    type: "postback",
                    label: "他の画像をさがす",
                    data: {:query => text}.to_s
                },
                {
                    type: "uri",
                    label: "画像を見る",
                    uri: image_url
                }
            ]
        }        
    end
     
    template = {
      type: "carousel",
      columns: columns
    }
     
    message = [{
      type: "template",
      altText: "こんな気分？",
      template: template
    }]
    Rails.logger.debug("message=#{message.inspect}")

    return message
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

    uri = URI.parse('http://api.tiqav.com/search.json?q=#{query}')
    json = Net::HTTP.get(uri)
    JSON.parse(json)
  end
  
end
