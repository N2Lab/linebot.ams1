class SendTextWorker
  @queue = :default # queue名を指定

  def self.perform(channel_secret, channel_token, mid, text)
    Rails.logger.debug("[SendTextWorker] mid=#{mid} text=${text}")
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = channel_secret
      config.channel_token = channel_token
    }
    Rails.logger.debug("[SendTextWorker] @client=#{@client.inspect}")

    message = {
      type: 'text',
      text: text
    }
    Rails.logger.debug("[SendTextWorker] message=#{message.inspect}")
    @client.push_message(mid, message)
  end

end