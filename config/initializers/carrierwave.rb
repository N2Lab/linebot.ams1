CarrierWave.configure do |config|
  config.fog_credentials = {
    provider: 'AWS',
    aws_access_key_id: 'AKIAJMP7Q44PFFV4FBZA', # s3_user
    aws_secret_access_key: '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',
    region: 'ap-northeast-1'
  }

  config.fog_directory = 'img.n2bot.net'
  config.asset_host = 'https://s3-ap-northeast-1.amazonaws.com/img.n2bot.net'
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