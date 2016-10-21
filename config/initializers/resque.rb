require 'resque'
require 'resque-scheduler'
require 'resque/scheduler/server'

Resque.redis = 'localhost:6379'
Resque.redis.namespace = "resque:mgr:#{Rails.env}" # アプリ毎に異なるnamespaceを定義しておく
