# Google Calendar API controller
# 
#
require 'google/api_client' # https://teratail.com/questions/26046
# NG require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

class GoogleCalController < ApplicationController

  require 'net/http'
  require 'uri'
  require 'json'

  def callback
    Rails.logger.debug("params=#{params}")
    Rails.logger.debug("request.raw_post=#{request.raw_post}")

    code = params[:code] # 短期間トークン If the user approves, then Google gives your application a short-lived access token

    # 長期間トークンを取得
    # 以下はコマンドラインでもOK
    # コマンドラインの場合
    # curl -d client_id=#{クライアントID} -d client_secret=#{クライアントシークレット} -d redirect_uri=#{リダイレクトURI} -d grant_type=authorization_code -d code=#{認証コード} https://accounts.google.com/o/oauth2/token

    # 参考 https://qiita.com/giiko_/items/b0b2ff41dfb0a62d628b

    # パラメータ
    q_hash = {
      client_id: "453886901491-evvsmmc5ei10tss4nlqab3f72k0ddmlh.apps.googleusercontent.com",
      client_secret: "_teiidDLMuEEyKN4JCVddsri",
      redirect_uri: "https://ams1.n2bot.net/oauth2callback",
      grant_type: "authorization_code",
      code: code
    }
    oauth_url = "https://accounts.google.com/o/oauth2/token"

    uri = URI(oauth_url)
    response = Net::HTTP.post_form(uri, q_hash)

    Rails.logger.debug("get token response=#{response}")
    Rails.logger.debug("get token response.body=#{response.try(:body)}")

    render text: "#{response.try(:body)}"
  end

  # Googleカレンダー変更時にコールされる
  # Unsubscribe Calendar
  # Channel には有効期限があるため、定期的に unsubscribe -> 再度 subscribe を行う必要があります。 Google::Apis::CalendarV3::CalendarService#watch_event の返り値が Google::Apis::CalendarV3::Channel のインスタンスですが、expiration という attribute に値が入っているので念のため, これも DB に保存しておきましょう。
  # ActiveJob とかに「期限が切れる 1h 前に unsubscribe -> subscribe して！」とかって渡しておくとかでもいいでしょう。
  # この際 Unix time (millisec 込み) が string として入っているので, datetime 型のカラムに保存する場合は Time.zone.at(channel.expiration.to_i / 1000.0) のようにする必要があります :sweat:
  # 一つのカレンダーを何回も subscribe しちゃうとカレンダーに何かしら予定を入れたりした際に、 channel の数分 callback が飛んでくるので注意してくださいmm
  # Channel に限らないんですが、APIで利用する様々なオブジェクトにはそれぞれ resource_id というものが割り振られているので、それも一緒に保存しておき、subscribe する際にはそれも一緒に使います。
  def webhook
    Rails.logger.debug("request=#{request}")
    Rails.logger.debug("params=#{params}")
    Rails.logger.debug("request.raw_post=#{request.raw_post}")

    # ヘッダーで事前通知かどうか判別する

    render text: "#{request.raw_post}"
  end
end
