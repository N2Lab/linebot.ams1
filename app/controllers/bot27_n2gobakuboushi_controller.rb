# N2 誤爆防止Bot
# グループ・ルームにマークを記録して
# 何か応答したらそのマークを必ず応答するBot
# テキストのみ指定可能
# マークは門田家 などで保存する
# 
# グループ・ルーム以外では固定メッセージを応答するだけ
# 
class Bot27N2gobakuboushiController < ApplicationController

  require 'line/bot'
  require 'net/http'
  require 'uri'
  require 'json'
  require 'kconv'

  BOT_ID = 27
  ATTR_MARK_ID = 1

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = "76670cbf5972ce770500f0f9a245ff45"
      config.channel_token = "u8KnWomxLQ4wDkMV0TsQwO0kivao15JFhS5YKeFBHW7s80thzCnjfw1z6Hjl296MhrubPIWemlFvjJXx7R/7aSxMoLk2GdwhHSburnUd4lHi/UtQ5ISD3KKrmihNg0WIOH6Bs72WUe6rNvjkwtLbrwdB04t89/1O/w1cDnyilFU="
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
      when Line::Bot::Event::Follow # ignore
          # message = execute_start_map(event, true)
          # response = client.reply_message(event['replyToken'], message)
        
      when Line::Bot::Event::Message # 個別,ルームまとめて対応
          message = execute_message(event)
          response = client.reply_message(event['replyToken'], message) unless message.blank?

      when Line::Bot::Event::Join # グループ・ルーム追加
        response = client.reply_message(event['replyToken'], on_join_grp(event))

      when Line::Bot::Event::Leave # グループ・ルーム退出 # ignore

      # when Line::Bot::Event::Postback # 他の画像を変換
      #   message = execute_postback(event)
      #   response = client.reply_message(event['replyToken'], message)
      end
    }
    
    Rails.logger.debug("response=#{response.try(:code)} #{response.try(:body)}")
  
    render text: ""
  end

  # グループ・ルーム参加時
  # 初回参加時は任意の動物名をマーク登録する
  def on_join_grp(event)
    type = event['source']['type']
    mid = nil
    case type
    when 'group'
      mid = event['source']['groupId']
    when 'room'
      mid = event['source']['roomId']
    end

    # 現在の設定を取得
    mark_attr = Attr.get(BOT_ID, mid, ATTR_MARK_ID)
    if mark_attr.blank?
      # マークを作成
      mark = create_random_default_mark
      mark_attr = Attr.create(BOT_ID, mid, ATTR_MARK_ID, 0, mark)
    end
    mark = mark_attr.text

    msg = "招待ありがとう！
このグループのマークは「#{mark}」です。
もし変更する場合は
マークは（設定したいマーク名）
とメッセージを送信してね！

例）佐藤家　をマークにしたい場合は以下のメッセージを送信してください
マークは佐藤家

マークには絵文字も利用できます。
スタンプ・画像は利用できません。
"
    [
      {
        type: 'text',
        text: msg
      }
    ]
  end

  # # 対象roomid or groupidのマークを保存
  # def save_mark(mid, mark)
  #   Attr.
  # end


  # ランダムデフォルトマークを返す
  def create_random_default_mark
    [
      "ひらがな",
      "あざらし",
      "あしか",
      "あなぐま",
      "あらいぐま",
      "ありくい",
      "あるまじろ",
      "いぐあな",
      "いたち",
      "いぬ",
      "いのしし",
      "いりおもてやまねこ",
      "うさぎ",
      "うし",
      "うま",
      "おおかみ",
      "おすぶた",
      "おたまじゃくし",
      "おっとせい",
      "おらんうーたん",
      "かえる",
      "かば",
      "かめ",
      "がらがらへび",
      "かわうそ",
      "かんがるー",
      "きつね",
      "きりん",
      "くま",
      "くろひょう",
      "こあら",
      "こいぬ",
      "こうし",
      "こうま",
      "こうもり",
      "こじか",
      "こねこ",
      "こひつじ",
      "コブラ",
      "こやぎ",
      "ごりら",
      "さい",
      "さらぶれっど",
      "さる",
      "さんしょううお",
      "しか",
      "しまうま",
      "じゃがー",
      "しろくま",
      "すかんく",
      "すなねずみ",
      "せいうち",
      "ぞう",
      "たぬき",
      "ちんぱんじー",
      "てながざる",
      "とかげ",
      "となかい",
      "とら",
      "なまけもの",
      "ねこ",
      "ねずみ",
      "はいいろぐま",
      "はいえな",
      "ばいそん",
      "ばく",
      "はつかねずみ",
      "ばっふぁろー",
      "はむすたー",
      "ぱんだ",
      "びーばー",
      "ひきがえる",
      "ひつじ",
      "ひとこぶらくだ",
      "ひひ",
      "ひょう",
      "ぶた",
      "ふたこぶらくだ",
      "へび",
      "ぽにー",
      "まんとひひ",
      "まんどりる",
      "めすぶた",
      "もぐら",
      "もるもっと",
      "やぎ",
      "やまあらし",
      "らいおん",
      "らくだ",
      "らっこ",
      "らば",
      "らま",
      "りす",
      "ろば",
      "わに",
    ].sample
  end

  # 全メッセージ応答メイン
  # 個別,ルーム,グループで切り返す
  def execute_message(event)
    unless groop_or_room?(event)
    # 個別の場合は固定メッセージで終了
      msg = 
        "このアカウントはルーム、グループに招待していただくと利用可能になります。

■このアカウントについて
N2誤爆防止Botは、ルーム・グループトーク毎に別々のマークを登録し、そのマークがメッセージ毎に応答されることで
ルーム・グループを確実に識別し、誤爆投稿防止をサポートするBotです。
※誤爆したメッセージを取り消すことはできません

■使いかた
1. ルーム・グループにこのアカウントを招待してください
2. 初期状態は任意の動物名がマークになります（ルーム・グループにメッセージを投稿すると、マークは「いぬ」です　といったメッセージが自動返信されます）
3. マークを変更したい場合は「マークは○○」といった形式でルーム・グループにメッセージを送信してください。
　例「マークはH5年同窓会」⇛H5年同窓会 がマークとなります
4. マークには絵文字も登録可能です

本アカウントに関するお問合わせは
https://www.facebook.com/n2lab.inc/
にメッセージ送信してお問い合わせください。"
      
      #配信メッセージ作成
      return [
            {
              type: 'text',
              text: msg
            },
      ]
    end

    # ルーム・グループの場合
    type = event['source']['type']
    mid = nil
    case type
    when 'group'
      mid = event['source']['groupId']
    when 'room'
      mid = event['source']['roomId']
    end

    # テキストメッセージで「マークはマルマル」に一致するか？
    case event.type
    when Line::Bot::Event::MessageType::Text
      text = event.message['text']
      m = text.match(/マークは(.+)/)
      if !m.blank? && !m[0].blank? && !m[1].blank? # 一致
        #マークを更新
        mark_attr = Attr.create(BOT_ID, mid, ATTR_MARK_ID, 0, m[1])
        msg = "マークを「#{mark_attr.text}」に更新しました"
        return [{type: 'text',text: msg}]
      end
    end

    # 一致しなければマークメッセージを応答
    msg = create_mark_reply_msg
    return [
          {
            type: 'text',
            text: msg
          },
    ]

  end

  # 現在のマークを応答
  def create_mark_reply_msg(event)
    type = event['source']['type']
    mid = nil
    case type
    when 'group'
      mid = event['source']['groupId']
    when 'room'
      mid = event['source']['roomId']
    end

    # 現在の設定を取得
    mark_attr = Attr.get(BOT_ID, mid, ATTR_MARK_ID)
    "マーク：#{mark_attr.try(:text)}"
  end
  
end
