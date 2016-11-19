# N2 せっかち君
# 
class Bot25N2sekkatikunController < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  require 'kconv'
  require 'active_support/core_ext/hash/conversions'
  require 'erb'
  include ERB::Util

  BOT_ID = 25
  # 無視KWリスト
  MENUS = ["前へ", "読む", "次へ"]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "56ea561f5f1ddf589140cd3ee51e1851"
      config.channel_token = "bMdRbN/K0z6ZxSj3CS51xXbbS5S59ZMnx1sVYWLzxC4+1xCulsNTDcJcCOxWGKxT66xCbjC2b37RwelGpvvMIvdP5EwUdu78tpGBMwUjNPZqJUJsoPGicj7fUasZBGEwjVVl+ACJI3zeJJZTfAG2JwdB04t89/1O/w1cDnyilFU="
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
          message = execute_reply(event)
          response = client.reply_message(event['replyToken'], message) unless message.blank?
          
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          # message = execute_start_map(event)
          # response = client.reply_message(event['replyToken'], message)
          
          # response = client.get_message_content(event.message['id'])
          # tf = Tempfile.open("content")
          # tf.write(response.body)
        end
      # when Line::Bot::Event::Postback # 回答したので答え合わせ
        # message = execute_answer_check(event)
        # response = client.reply_message(event['replyToken'], message)
      end
    }
    
    Rails.logger.debug("response=#{response.try(:code)} #{response.try(:body)}")
  
    render text: ""
  end
  
  GOOGLE_API_KEY = "AIzaSyAbAK1ASX-AnyDe9QEcurKplj7ajDMmIxI"
  
  # 返信
  def execute_reply(event)
    text = event.message['text']
    source_type = event["source"]['type']
    messages = []
    
    # 1. call Google Cloud Natural Language API and parse
    #  language.documents.analyzeEntities = Entities（固有表現抽出）
    #  Syntax（形態素解析、係り受け解析）
    # まずは Entities で Location > ルート検索 などを対応する
    res = google_api_natural_lang_entities(GOOGLE_API_KEY, text)
    
    # 2. entities 有無で分岐
    entities = res["entities"]
    # ルーム＆グループでマッチなしは応答なし
    return messages if ["group", "room"].include?(source_type) && entities.blank?

    # 個人でマッチなしは固定応答
    if entities.blank?
      # debug
      # messages << {
        # type: 'text',
        # text: res.inspect
      # }
    
      messages << {
        type: 'text',
        text: "何か調べる？。
地名人名など自由に入れてね􀄃􀄃laugh􏿿"
      }
      return messages
    end
    
    # ここから分析&メッセージ作成処理
    # template = {
      # type: "carousel",
      # columns: columns
    # }
# #     
    
    message = [{
      type: "template",
      altText: "せっかち君が先に調べたよ！",
      template: {
        :type => "carousel",
        :columns => create_templa1te_columns_by_entities(entities)
      }
    }]
    Rails.logger.debug("message=#{message.inspect}")
    message
  end
  
  # 固有表現抽出結果から応答メッセージを組み立て
  # column を返す
  def create_template_columns_by_entities(entities)
    messages = []
    max_loop = [5, entities.count].min
    for i in 0..max_loop-1
      en = entities[i]
      # type で メッセージを変える
      case en["type"]
      when "LOCATION"
        messages << create_location_msg(en)
      # when "CONSUMER_GOOD"
        # messages << create_good_msg(en)
      else
        messages << create_default_msg(en)
      end
    end
    messages
  end
  
  # 位置情報Msg
  # ルート・地図表示
  # google検索
  # 周辺情報 > じゃらんとか
  # type=LOCATION
  def create_location_msg(en)
    name = en["name"]
    type = en["type"]
    # TODO できれば毎回異なる画像を返したい 画像検索URLか
    # 1. 画像検索
    image_url = "https://lh4.ggpht.com/mJDgTDUOtIyHcrb69WM0cpaxFwCNW6f0VQ2ExA7dMKpMDrZ0A6ta64OCX3H-NMdRd20=w300-rw"

    # ルート情報
    route_map_url = "https://maps.google.co.jp/maps?q=#{url_encde(name)}&iwloc=A"
    near_spots_url = "http://map.google.jp"
    near_lanch_url = "http://map.google.jp"
    text = "「#{name}の情報だよ！"
    {
        # thumbnailImageUrl: image_url,
        # title: "「#{name}」を調べたよ！",
        text: text,
        actions: [
            # {
                # type: "postback",
                # label: "ルート・地図をトークに共有",
                # data: "action=research"
            # },
            {
                type: "uri",
                label: "ルート・地図",
                uri: route_map_url
            },
            # {
                # type: "uri",
                # label: "周辺スポット",
                # uri: near_spots_url
            # },
            # {
                # type: "uri",
                # label: "周辺ランチ",
                # uri: near_lanch_url
            # },
        ]
    }     
    # {
        # type: 'text',
        # text: "create_good_msg"
    # }
  end

  # def create_good_msg(en)
    # {
        # type: 'text',
        # text: "create_good_msg"
    # }
  # end

  # その他デフォルト
  # type=ORGANIZATION,COMMON,EVENT など
  # wikipedia_urlがあればそのリンクと画像を返したい
  def create_default_msg(en)
    name = en["name"]
    type = en["type"]
    wiki_url = "https://www.google.co.jp/search?hl=ja&q=#{name}"
    image_url = "https://lh4.ggpht.com/mJDgTDUOtIyHcrb69WM0cpaxFwCNW6f0VQ2ExA7dMKpMDrZ0A6ta64OCX3H-NMdRd20=w300-rw"
    text = "「#{name}」を調べたよ！"
    
    #wiki urlがあれば利用する
    if en["metadata"].present?
      wiki_url = en["metadata"]["wikipedia_url"] if en["metadata"]["wikipedia_url"].present?
    end

    {
        # thumbnailImageUrl: image_url, # 一旦省略
#        title: "「#{name}」を調べたよ！", # 一旦省略
        text: text,
        actions: [
            # {
                # type: "postback",
                # label: "ルート・地図をトークに共有",
                # data: "action=research"
            # },
            {
                type: "uri",
                label: "くわしくみたい",
                uri: wiki_url
            }
        ]
    }       

  end

end
