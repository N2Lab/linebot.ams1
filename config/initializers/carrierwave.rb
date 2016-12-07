CarrierWave.configure do |config|
  config.fog_credentials = {
    provider: 'AWS',
    aws_access_key_id: 'AKIAIMAF3W6LDEFP7RIQ', # s3_user
    aws_secret_access_key: File.read('/home/deployuser/s3user_2.secret.key').strip,
    region: 'ap-northeast-1'
  }

  config.fog_directory = 'img.n2bot.net'
  config.asset_host = 'https://s3-ap-northeast-1.amazonaws.com/img.n2bot.net'
  config.cache_dir = "#{Rails.root}/tmp/uploads"
  # case Rails.env
  #   when 'production'
  #     config.fog_directory = 'img.n2bot.net'
  #     config.asset_host = 'https://s3-ap-northeast-1.amazonaws.com/dummy'

  #   when 'development'
  #     config.fog_directory = 'img.n2bot.net'
  #     config.asset_host = 'https://s3-ap-northeast-1.amazonaws.com/dev.dummy'

  #   when 'test'
  #     config.fog_directory = 'img.n2bot.net'
  #     config.asset_host = 'https://s3-ap-northeast-1.amazonaws.com/test.dummy'
  # end
end