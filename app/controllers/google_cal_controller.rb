# Google Calendar API controller
# 
class GoogleCalController < ApplicationController

  require 'net/http'
  require 'uri'
  require 'json'

  def callback
    Rails.logger.debug("params=#{params}")
    render text: ""
  end
end
