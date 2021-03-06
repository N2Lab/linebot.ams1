# キーワードからネタ画像を返す ランダム画像を返す bot
# 1. http://api.tiqav.com/search/random.json
# 2. http://img.tiqav.com/[id].[ext] で画像をテンプレートメッセージで返して次の画像へ
# TODO 画像からタグ検索してタグを選択肢に表示
class Bot10N2imgsearchController < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  
  BOT_ID = 10
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "b39f1f66dbfc21b0397a26fdb41c5ed8"
      config.channel_token = "66+9pgE27LdckXiBTc/jgfKcsVYxhvLw2koo4FJshZJh8/nd6GkORVx6tROAYbCsn6C4omjadwYkQBBBsTx6RE8WEHLLkx9LjBby0NEFtLQ9CAKciPiAdWpCnnhfD29+u+0yKUPSZIXqzKW3mWoI3gdB04t89/1O/w1cDnyilFU="
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
          message = execute_text(event)
          response = client.reply_message(event['replyToken'], message)
          # 下記はプロプランのみ
          # Resque.enqueue(SendTextWorker, client.channel_secret, client.channel_token, event.message['id'], "worker")
          
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      when Line::Bot::Event::Postback # 他の画像
        response = client.reply_message(event['replyToken'], execute_text(event))
      end
    }
    
    Rails.logger.debug("response=#{response.code} #{response.body}")
  
    render text: "OK"
  end

  # メインロジック (テキストメッセージ)
  def execute_text(event)
#    text = event.message['text']

    # OK
    # return [
          # {
            # type: 'text',
            # text: "テスト"
          # }
    # ]
    # image test OK
    # image_url = "https://img.tiqav.com/5AX.jpg"
    # return [{
    # type: "image",
    # originalContentUrl: image_url,
    # previewImageUrl: image_url
# }]
    # template & buttons
    image_list = get_random_image_list()
    # [{"id":"5AX","ext":"jpg","height":219,"width":333,"source_url":"http://mar.2chan.net/jun/b/src/1343375952522.jpg"},
      # {"id":"sg","ext":"jpg","height":531,"width":419,"source_url":"http://feb.2chan.net/jun/b/src/1258964461577.jpg"},
    
#    Rails.logger.debug("image_list=#{image_list.inspect}")
    
    # Buttonsメッセージの場合 1件だけ表示 OK
    # img = image_list.first
    # image_url = "https://img.tiqav.com/#{img["id"]}.#{img["ext"]}"
#     
    # message = 
    # [
      # {
  # type: "template",
  # altText: "this is a buttons template",
  # template: {
      # type: "buttons",
      # thumbnailImageUrl: image_url,
      # title: "おすすめネタ画像です！",
      # text: image_url,
      # actions: [
          # {
            # type: "postback",
            # label: "他の画像をさがす",
            # data: "action=other"
          # },
          # {
            # type: "uri",
            # label: "画像を見る",
            # uri: image_url
          # }
      # ]
  # }
# }]
#     
    # Rails.logger.debug("message=#{message.inspect}")
    # return message    
    # カルーセルの場合 ... うまく動作しないのでやめる
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
                    data: "action=research"
                },
                {
                    type: "uri",
                    label: "画像を見る",
                    uri: image_url
                }
            ]
        }        
    end
     
    # img = image_list.first
    # image_url = "http://img.tiqav.com/#{img["id"]}.#{img["ext"]}"
          # columns = [ {
            # thumbnailImageUrl: image_url,
            # title: "おすすめネタ画像です！",
            # text: "description",
            # actions: [
                # {
                    # type: "postback",
                    # label: "他の画像をさがす",
                    # data: "action=research"
                # }
            # ]
        # }  
        # ]
    template = {
      type: "carousel",
      columns: columns
    }
#     
    message = [{
      type: "template",
      altText: "ネタ画像をどうぞ",
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
end
