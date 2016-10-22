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
          Rails.logger.debug("item.=#{item.inspect}")
          Rails.logger.debug("img url=#{get_img(item.link).inspect}")
        }
      rescue => e
        Rails.logger.error(e)
      end
    end
    return result
  end
  
  def self.get_img(url)
     charset = nil
     html = open(url) do |f|
       charset = f.charset
       f.read
     end
     doc = Nokogiri::HTML.parse(html, nil, charset)
     images = doc.xpath("//img[@width>300]/@src")
     images.first
 end
  
end
