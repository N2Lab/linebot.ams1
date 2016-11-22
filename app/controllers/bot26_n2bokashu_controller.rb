# N2 ぼかっしゅ
# ユーザーが画像を送信してきたら
#   カルーセル数パターンボカッシュ結果を返す, ボタンはダウンロード
# テキスト送信なら使い方
# 
class Bot26N2bokashuController < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  require 'kconv'
  require 'active_support/core_ext/hash/conversions'
  require 'erb'
  include ERB::Util

  BOT_ID = 26

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "759f90d2c5fb7ea8cb9d09b26f75dceb"
      config.channel_token = "aYyf2bqDnh2eEWyXnt0dNWVo+RqvMZCJJYt4RWRY1wwUQdfAYtFToN2iVhFZooLVMcxTou9SRFeG0jmxCYoa7TVeSJWcZStUEhAdjoJwWiw7LKyIObyMHjvfI3ySWESlJSKoboxVUT6cL8t+sQkqoAdB04t89/1O/w1cDnyilFU="
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
          # message = execute_start_map(event, true)
          # response = client.reply_message(event['replyToken'], message)
        
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = execute_text(event)
          response = client.reply_message(event['replyToken'], message) unless message.blank?
          
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          message = execute_image(event)
          response = client.reply_message(event['replyToken'], message) unless message.blank?
          
        end
      # when Line::Bot::Event::Postback # 回答したので答え合わせ
        # message = execute_answer_check(event)
        # response = client.reply_message(event['replyToken'], message)
      end
    }
    
    Rails.logger.debug("response=#{response.try(:code)} #{response.try(:body)}")
  
    render text: ""
  end
  
  # テキストメッセージ応答メイン
  def execute_text(event)
    # ランダムメッセージ
    msgs = [
      "使い方",
      "こんな写真を送ってね",
      "グループでも利用できるよ",
    ]
    msg = msgs.sample
    #配信メッセージ作成
    return [
          {
            type: 'text',
            text: msg
          },
    ]
  end

  # 画像メッセージ応答メイン
  def execute_image(event)
    # 面倒なのでs3 nfs?
          # response = client.get_message_content(event.message['id'])
          # tf = Tempfile.open("content")
          # tf.write(response.body)

    # 応答メッセージ返信
    image_url = "https://pbs.twimg.com/media/Cw_MqqGVEAAPL6F.jpg" # 仮
    [{
      type: "image",
      originalContentUrl: image_url,
      previewImageUrl: image_url
      }
    ]
  end

end