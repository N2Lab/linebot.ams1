class SendTextWorker
  @queue = :default # queue名を指定

  def self.perform(channel_secret, channel_token, mid, text)
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = channel_secret
      config.channel_token = channel_token
    }

    message = {
      type: 'text',
      text: text
    }
    @client.push_message(mid, message)
  end

end