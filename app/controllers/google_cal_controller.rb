# Google Calendar API controller
# 
class GoogleCalController < ApplicationController

  require 'net/http'
  require 'uri'
  require 'json'

  def callback
    render text: ""
  end
end
