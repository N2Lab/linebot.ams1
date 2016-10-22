#

# @author
#
require 'rss'
class NewsFeed < ActiveRecord::Base
  
  # 各フィードの最新のニュースを取得して array の hashで返す
  def self.get_news_hash_array()
    result = []
    NewsFeed.all.each_with_index do |nf,i|
      begin
        rss = RSS::Parser.parse(nf.url)
        rss.items.each{|item|
          Rails.logger.debug("item.title=#{item.title}")
          Rails.logger.debug("item.link=#{item.link}")
          Rails.logger.debug("item.description=#{item.description}")
        }
      rescue => e
        Rails.logger.error(e)
      end
    end
    return result
  end
  
end
