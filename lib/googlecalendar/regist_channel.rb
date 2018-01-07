require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'https://ams1.n2bot.net/google_cal/callback'
# OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Google Calendar API Ruby Quickstart'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "calendar-ruby-quickstart.yaml")
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR
# SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY

TIME_ZONE = "Asia/Tokyo"

def client_options
  {
    client_id: "453886901491-evvsmmc5ei10tss4nlqab3f72k0ddmlh.apps.googleusercontent.com",
    client_secret: "_teiidDLMuEEyKN4JCVddsri",
    authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
    token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
    scope: SCOPE,
    redirect_uri: OOB_URI
  }
end

def auth_options
 {
  access_token: "ya29.Gls7BZUMANv5-3_mMgQ71tCl4GmCiZi02-6Xr6EpscpUX4ZV8w9AHKjEdN2ZkFiKDpM5nC4qRHw4kkRabGY68Gmvsb5deJH5g5e7AqmoaDhCCuIfmexyZvFqtueU", # 実際はDBから取得
  # expires_in: 3600,
  refresh_token: "1/ZuhPoLv3PML8x6WFhlCPtB-0FRu-7cDGOI5dZb5o4A0",
  token_type: "Bearer"
 } 
end

# 認証情報を構築
client = Signet::OAuth2::Client.new(client_options)
client.update!(auth_options)

# Initialize the API
service = Google::Apis::CalendarV3::CalendarService.new
service.authorization = client

calendar_id = 'primary' # カレンダーを変更する場合はここで指定する

# 監視開始(channel 登録)
channel_id = 'test_channel_2' # 任意のIDを指定可能
success_callback_url = 'https://ams1.n2bot.net/google_cal/webhook' # イベント変更時に通知されるURL
channel = Google::Apis::CalendarV3::Channel.new(address: success_callback_url, id: channel_id, type: "web_hook")
res = service.watch_event(calendar_id, channel, single_events: true, time_min: Time.now.iso8601)

puts "Webhook channel 登録結果 #{res.inspect}"
