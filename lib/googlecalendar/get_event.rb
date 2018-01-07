require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'https://ams1.n2bot.net/google_cal/callback'
APPLICATION_NAME = 'Google Calendar API Ruby Quickstart'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "calendar-ruby-quickstart.yaml")
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR
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

# Fetch the next 10 events for the user
calendar_id = 'primary' # カレンダーを変更する場合はここで指定する

# 10件取得
res = service.list_events(calendar_id,
                                max_results: 10,
                                single_events: true,
                                order_by: 'startTime',
                                time_min: Time.now.iso8601)

puts "取得イベント数 #{res.items.count}"
res.items.each_with_index do |event,i|
  start = event.start.date || event.start.date_time
  puts "- #{event.summary} (#{start})"
end
