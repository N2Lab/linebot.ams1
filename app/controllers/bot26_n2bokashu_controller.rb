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
  include Magick
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

  # 変換ロジック定義
  # http://imagemagick.rulez.jp/archives/432
  # (radius)は、ぼかすピクセル範囲、(sigma)はぼかし量に影響を与えます。
  CONVERTS = [
    # ["ふわっと", "img.blur_image(10.0, 5.0)"],
    # ["おっとり", "img.blur_image(10.0, 10.0)"],
    # ["オールドレンズA", "img.radial_blur(6.0)"],
    # ["オールドレンズB", "img.radial_blur(15.0)"],

    # マスクxぼかし を試す
    # まずはグラディエーションを作成
#    ["Gradiation", "Magick::Image.new(100,100,Magick::GradientFill.new(0, 0, 0, 100, '#900', '#000')) { self.background_color = 'red'; self.format = 'PNG' }"], # 左右黒
#    ["Gradiation", "Magick::Image.new(img.columns,img.rows,Magick::GradientFill.new(0, 0, img.columns, 0, '#fff', '#000')) { self.background_color = 'white'; self.format = 'PNG' }"], # 上白>下黒


    # ぼかしマスクあり  
    # ["上から見た", "img.add_compose_mask(Magick::Image.new(img.columns,img.rows,Magick::GradientFill.new(0, 0, img.columns, 0, '#fff', '#000')) { self.background_color = 'white'; self.format = 'PNG' })", "img.blur_image(30.0, 5.0)"], # GradMask 上ぼけ 下なし 上白>下黒マスク, ぼかし
    # # ["GradMask 下ぼけ 上なし1", "Magick::Image.new(img.columns,img.rows,Magick::GradientFill.new(0, 0, 0,    img.rows, '#fff', '#000')) { self.background_color = 'white'; self.format = 'PNG' }"], # 左ボケ 右なし
    # ["下から見た", "img.add_compose_mask(Magick::Image.new(img.columns,img.rows,Magick::GradientFill.new(0, 0, img.columns, 0, '#000', '#fff')) { self.background_color = 'white'; self.format = 'PNG'})", "img.blur_image(30.0, 5.0)"], # GradMask 下ぼけ 上なし 上白>下黒マスク, ぼかし
# TODO img = から　eval記載とする
#    ["GradMask 中心からぼかすマスク(白背景,水色)", "mask = Magick::ImageList.new().read('radial-gradient:#7799ff-#ffffff'){ self.size = '200x200'; self.format = 'PNG'}.first; mask.format = 'PNG'; img = mask"], # 
#    ["GradMask 中心からぼかすマスク(白背景,黒)", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = mask"], # 
    # ["GradMask 1中心からぼかすマスク(白背景,黒)", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 5.0)"], # 少しぼける
    # ["ノーマル", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)"], #
    # ["めちゃぼけ", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(40.0, 30.0)"], #
    # ["オールドレンズ", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img.radial_blur(12.0)"], #
    # ["ハイキー", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img = img.modulate(150, 150)"], #
    # ["ローキー", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img = img.modulate(60, 50)"], #
    # ["モノクロ", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img.colorspace = GRAYColorspace"], #
    # ["モノクロハイキー", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img.colorspace = GRAYColorspace", "img = img.modulate(150, 150)"], #
    # ["モノクロローキー", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img.colorspace = GRAYColorspace", "img = img.modulate(60, 50)"], #
    # ["セピア", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.sepiatone(80)"], #
    ["白黒", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img = img.colorspace = HWBColorspace"], #

    # ["GradMask 3中心からぼかすマスク(白背景,黒)", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 25.0)"], #

  # TODO 中心移動可能に or 目を探す
    # 合成 > あとで
#    ["夢の中", "img.composite(img, 30, 30, Magick::OverCompositeOp)"], # 30,30右下に重ねる

    # selective_blur_channel > 保留 全体がぼけてしまう
    # ["ポートレート1", "img.selective_blur_channel(10.0, 5.0, 30)"],
    # ["ポートレート2", "img.selective_blur_channel(10.0, 5.0, 50)"],
    # ["ポートレート3", "img.selective_blur_channel(10.0, 5.0, 60)"],
    # ["ポートレート4", "img.selective_blur_channel(10.0, 5.0, 70)"],
    # ["ポートレート5", "img.selective_blur_channel(10.0, 5.0, 80)"],
    # ["ポートレート6", "img.selective_blur_channel(10.0, 10.0, 30)"],
    # ["ポートレート7", "img.selective_blur_channel(10.0, 10.0, 50)"],
    # ["夢の国5", "img.blur_image(20.0, 10.0)"],
    # ["夢の国6", "img.blur_image(20.0, 10.0)"],
    # ["夢の国7", "img.blur_image(20.0, 10.0)"],
    # ["夢の国8", "img.blur_image(20.0, 10.0)"],
    # ["夢の国9", "img.blur_image(20.0, 10.0)"],
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
    convs = CONVERTS.sample(1) # 5だと重い , 3 でもだめ,,
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
      #img = eval(c) if i > 0 # i=0は名前
      eval(c) if i > 0 # i=0は名前
      # img.destroy!
      # img = img2
      # TODO メモリ解放
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
