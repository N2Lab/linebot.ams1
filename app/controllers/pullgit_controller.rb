class PullgitController < ApplicationController
  def index
    Rails.logger.info("PullgitController start")
    Rails.logger.info(`/var/www/sh/pull.sh`)
    render text: ""
  end
end