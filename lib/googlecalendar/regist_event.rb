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

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
# def authorize
#   FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

#   client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
#   token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
#   authorizer = Google::Auth::UserAuthorizer.new(
#     client_id, SCOPE, token_store)
#   user_id = 'default'
#   credentials = authorizer.get_credentials(user_id)
#   if credentials.nil?
#     url = authorizer.get_authorization_url(
#       base_url: OOB_URI)
#     puts "Open the following URL in the browser and enter the " +
#          "resulting code after authorization"
#     puts url
#     code = gets
#     credentials = authorizer.get_and_store_credentials_from_code(
#       user_id: user_id, code: code, base_url: OOB_URI)
#   end
#   credentials
# end

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

# 登録するイベント内容
evt_start = DateTime.now
evt_end = evt_start + Rational(1, 24) 
summary = "Test登録予定 #{evt_start}"
description = "テストです"
location = "ホールA"
h_tmp = {
  summary: summary,
  description: description,
  location: location,
  start: {
    date_time: evt_start.iso8601,
    time_zone: TIME_ZONE
  },
  end: {
    date_time: evt_end.iso8601,
    time_zone: TIME_ZONE 
  }
}

event = Google::Apis::CalendarV3::Event.new(h_tmp)
res = service.insert_event(calendar_id, event)
puts "イベント登録成功 イベントURL = #{res.html_link}"
puts "レスポンス詳細 = #{res.inspect}"


# response = service.list_events(calendar_id,
#                                max_results: 10,
#                                single_events: true,
#                                order_by: 'startTime',
#                                time_min: Time.now.iso8601)

# puts "Upcoming events:"
# puts "No upcoming events found" if response.items.empty?
# response.items.each do |event|
#   start = event.start.date || event.start.date_time
#   puts "- #{event.summary} (#{start})"
# end