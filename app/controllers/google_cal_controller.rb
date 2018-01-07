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
    uri = URI('https://accounts.google.com/o/oauth2/revoke')
    get_token_params = { :token => code }
    uri.query = URI.encode_www_form(get_token_params)
    response = Net::HTTP.get(uri)

    Rails.logger.debug("get token response=#{response}")

    render text: "#{response.inspect}"
  end
end
