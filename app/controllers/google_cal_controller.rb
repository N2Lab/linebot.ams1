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
    # 参考 https://qiita.com/giiko_/items/b0b2ff41dfb0a62d628b
    # 自己入力部分

    # 自動部分
    q_hash = {
      client_id: "453886901491-evvsmmc5ei10tss4nlqab3f72k0ddmlh.apps.googleusercontent.com",
      client_secret: "_teiidDLMuEEyKN4JCVddsri",
      redirect_uri: "https://ams1.n2bot.net/oauth2callback",
      scope: "https://www.googleapis.com/auth/calendar",
      response_type: "code",
      approval_prompt: "force",
      access_type: "offline"
    }
    query = q_hash.to_query
    oauth_url = "https://accounts.google.com/o/oauth2/auth?#{query}"

#    oauth_url = "https://accounts.google.com/o/oauth2/auth?client_id=#{client_id}&redirect_uri=#{redirect_uri}&scope=#{scope}&response_type=code&approval_prompt=force&access_type=offline"

    uri = URI(oauth_url)
    response = Net::HTTP.get(uri)

    Rails.logger.debug("get token response=#{response}")

    render text: "#{response.inspect}"
  end
end
