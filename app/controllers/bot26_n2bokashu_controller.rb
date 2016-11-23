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
  require 'rmagick'
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

  CONVERTS = [
    ["夢の国1", "img.blur_image(5.0, 2.5)"],
    ["夢の国2", "img.blur_image(20.0, 10.0)"],
    ["夢の国3", "img.blur_image(20.0, 10.0)"],
    ["夢の国4", "img.blur_image(20.0, 10.0)"],
    ["夢の国5", "img.blur_image(20.0, 10.0)"],
    ["夢の国6", "img.blur_image(20.0, 10.0)"],
    ["夢の国7", "img.blur_image(20.0, 10.0)"],
    ["夢の国8", "img.blur_image(20.0, 10.0)"],
    ["夢の国9", "img.blur_image(20.0, 10.0)"],
  ]

  # 画像メッセージ応答メイン
  def execute_image(event)
    mid = event['source']['userId']
    msg_id = event.message['id']

    # get image to file. 面倒なのでs3 nfs?
    # response = client.get_message_content(event.message['id'])
    # tf = Tempfile.open("content")
    # tf.write(response.body)

    response = client.get_message_content(msg_id)
    tf = Tempfile.open("content_#{msg_id}")
    tf.binmode
    tf.write(response.body)
    @uploader ||= ::ImageUploader.new
    @uploader.store_dir = "public/bot#{BOT_ID}/#{mid}/#{msg_id}/"
    @uploader.store!(tf) # up to s3
    Rails.logger.info("uploaded path=#{tf.path}")

    # original image s3 url
    # https://s3-ap-northeast-1.amazonaws.com/img.n2bot.net/public/bot26/Ueb7eed3a750376f6d5b47b73bbc5fbe4/5246240367991/content_524624036799120161123-6511-1jnbhvp

    # original image cf url
    # https://img.n2bot.net/bot26/Ueb7eed3a750376f6d5b47b73bbc5fbe4/5246240367991/content_524624036799120161123-6511-1jnbhvp

    # example for uploader
    # product.image.url          # => '/url/to/file.png'
    # product.image.current_path # => 'path/to/file.png'
    # prodcut.image.identifier   # => 'file.png'
    # product.image?   # => imageがあるかを true or false で返す

    # create Magick:Image
    org_img = Magick::Image.read(tf.path).first

    columns = []

    # 変換ロジック5個抽出
    convs = CONVERTS.sample(5)
    convs.each_with_index do |conv,i|
      columns << convert_image(conv, org_img, mid, msg_id, tf.path, i)
    end

    # カルーセルで出力
    template = {
      type: "carousel",
      columns: columns
    }
#     
    message = [{
      type: "template",
      altText: "こんな写真どう？",
      template: template
    }]

  end

  # 引数のロジックでimgを変換してアップしcolumnsを返す
  def convert_image(conv, img, mid, msg_id, org_img_path, times)
    conv.each_with_index do |c, i|
      img2 = eval(c) if i > 0 # i=0は名前
      img.destroy!
      img = img2
    end

    new_f = Tempfile.open("img_#{msg_id}_#{times}")
    new_f.binmode
    new_f.write(img.to_blob)
    # img.destroy!

    @uploader ||= ::ImageUploader.new
    @uploader.store_dir = "public/bot#{BOT_ID}/#{mid}/#{msg_id}/"
    @uploader.store!(new_f)

    Rails.logger.info("conv = #{conv.inspect}")
    Rails.logger.info("new_f = #{new_f.inspect}")
    filename = File.basename(new_f)

    # Rails.logger.info("store_res = #{store_res.inspect}")
    image_url = "https://img.n2bot.net/bot26/#{mid}/#{msg_id}/#{filename}"
    {
          thumbnailImageUrl: image_url,
          # title: "xxxx風",
          text: "#{conv.first}風",
          actions: [
              {
                  type: "postback",
                  label: "他の加工をみる",
                  data: {:action => "other", :mid => mid, :msg_id => msg_id, :org_img_path => org_img_path}.to_s
              },
              {
                  type: "uri",
                  label: "ダウンロード",
                  uri: image_url
              }
          ]
      }        


  end

end
