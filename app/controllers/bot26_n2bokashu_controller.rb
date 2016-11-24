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
      Rails.logger.info("event.class=#{event.class}")
      save_user(BOT_ID, event)
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
      when Line::Bot::Event::Postback # 他の画像を変換
        message = execute_postback(event)
        response = client.reply_message(event['replyToken'], message)
      end
    }
    
    Rails.logger.debug("response=#{response.try(:code)} #{response.try(:body)}")
  
    render text: ""
  end
  
  # テキストメッセージ応答メイン
  def execute_text(event)
    return [] if groop_or_room?(event) # グループルームテキストは何も返さない

    # ランダムメッセージ
    msgs = [
      "使い方
1. 画像をこのトークに送信してね
2. 少し待つとぼかっしゅが加工した画像を返信するよ。ぼかすのは
3. 画像の詳細確認・ダウンロードは「ダウンロード」を選んでね
4. 「他の加工をみる」で他の加工も確認できるよ",
      "こんな写真を送ってね
・顔が中心にある写真
",
      "グループでも利用できるよ
・グループ/ルームにこのアカウントを招待してね
・招待中に画像を送ってくれると同じように加工画像を返信するよ",
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
    ["オールドレンズA", "img = img.radial_blur(4.0)"],
    ["オールドレンズB", "img = img.radial_blur(10.0)"],

    # ぼかしマスクあり  
    # ["上から見た", "img.add_compose_mask(Magick::Image.new(img.columns,img.rows,Magick::GradientFill.new(0, 0, img.columns, 0, '#fff', '#000')) { self.background_color = 'white'; self.format = 'PNG' })", "img.blur_image(30.0, 5.0)"], # GradMask 上ぼけ 下なし 上白>下黒マスク, ぼかし
    # # ["GradMask 下ぼけ 上なし1", "Magick::Image.new(img.columns,img.rows,Magick::GradientFill.new(0, 0, 0,    img.rows, '#fff', '#000')) { self.background_color = 'white'; self.format = 'PNG' }"], # 左ボケ 右なし
    # ["下から見た", "img.add_compose_mask(Magick::Image.new(img.columns,img.rows,Magick::GradientFill.new(0, 0, img.columns, 0, '#000', '#fff')) { self.background_color = 'white'; self.format = 'PNG'})", "img.blur_image(30.0, 5.0)"], # GradMask 下ぼけ 上なし 上白>下黒マスク, ぼかし
# TODO img = から　eval記載とする
#    ["GradMask 中心からぼかすマスク(白背景,水色)", "mask = Magick::ImageList.new().read('radial-gradient:#7799ff-#ffffff'){ self.size = '200x200'; self.format = 'PNG'}.first; mask.format = 'PNG'; img = mask"], # 
#    ["GradMask 中心からぼかすマスク(白背景,黒)", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = mask"], # 
    # ["GradMask 1中心からぼかすマスク(白背景,黒)", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 5.0)"], # 少しぼける
    ["ややぼけ", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(10.0, 5.0)"], #
    ["ノーマル", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)"], #
    ["めちゃぼけ", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(40.0, 30.0)"], #

    # ["オールドレンズ", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img.radial_blur(12.0)"], #
    # ["ハイキー", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img = img.modulate(150, 150)"], #
    # ["ローキー", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img = img.modulate(60, 50)"], #
    # ["モノクロ", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img.colorspace = GRAYColorspace"], #
    # ["モノクロハイキー", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img.colorspace = GRAYColorspace", "img = img.modulate(150, 150)"], #
    # ["モノクロローキー", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img.colorspace = GRAYColorspace", "img = img.modulate(60, 50)"], #
    # ["セピア", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.sepiatone(80)"], #
    # ["魔女", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img.colorspace = HWBColorspace"], # 紫になる
    # ["すりガラスA", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img.colorspace = GRAYColorspace", "img = img.spread(3)"], # # Spread 1
    # ["すりガラスB", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img.colorspace = GRAYColorspace", "img = img.spread(5)"], # # Spread 1
    ["すりガラス", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img.colorspace = GRAYColorspace", "img = img.spread(10)"], # # Spread 1

    # ["夕焼け", "img = img.colorize(0.8, 0.5, 0.5, '#E09030')", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)"], # オレンジっぽく
    # ["寒い冬", "img = img.colorize(0.5, 0.6, 0.8, '#2040D0')", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)"], # オレンジっぽく
    # ["新緑", "img = img.colorize(0.8, 0.5, 0.5, '#20DD20')", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)"], # オレンジっぽく

    ["トリップ", "mask = Magick::ImageList.new().read('radial-gradient:#000000-#ffffff'){ self.size = img.columns.to_s + 'x' + img.rows.to_s; self.format = 'PNG'}.first; mask.format = 'PNG'; img = img.add_compose_mask(mask)", "img = img.blur_image(30.0, 20.0)", "img = img.cycle_colormap(10)"], # 

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

    create_convert_img_message(mid, msg_id, tf.path)

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
#     org_img = Magick::Image.read(tf.path).first

#     columns = []

#     # 変換ロジック5個抽出
#     convs = CONVERTS.sample(2) # 5だと重い , 3 でもだめ,,
#     convs.each_with_index do |conv,i|
#       columns << convert_image(conv, org_img, mid, msg_id, tf.path, i)
#     end

#     # カルーセルで出力
#     template = {
#       type: "carousel",
#       columns: columns
#     }
# #     
#     message = [{
#       type: "template",
#       altText: "こんな写真どう？",
#       template: template
#     }]

  end

  # postback 応答メイン
  # 最後に変換した画像を再度変換する
  def execute_postback(event)
    mid = event['source']['userId']
    postback = event["postback"]
    data = eval(postback["data"])
    Rails.logger.debug("data = #{data.inspect}")
    tmp_file_path = data[:org_img_path]
    msg_id = data[:msg_id]

    create_convert_img_message(mid, msg_id, tmp_file_path)

  end

  def create_convert_img_message(mid, msg_id, tmp_file_path)
    # create Magick:Image for org image
    org_img = Magick::Image.read(tmp_file_path).first

    columns = []

    # 変換ロジック5個抽出
    convs = CONVERTS.sample(2) # 5だと重い , 3 でもだめ,,
    convs.each_with_index do |conv,i|
      columns << convert_image(conv, org_img, mid, msg_id, tmp_file_path, i)
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
