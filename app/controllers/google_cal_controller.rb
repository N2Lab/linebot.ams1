# Google Calendar API controller
# 
class GoogleCalController < ApplicationController

  require 'net/http'
  require 'uri'
  require 'json'

  def callback
    Rails.logger.debug("params=#{params}")
    Rails.logger.debug("request.raw_post=#{request.raw_post}")
    render text: ""
  end
end
