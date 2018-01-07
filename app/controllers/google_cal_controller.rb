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

    render text: "#{response.inspect}"
  end
end
