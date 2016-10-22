#

# @author
#
require 'rss'
class NewsFeed < ActiveRecord::Base
  
  # 各フィードの最新のニュースを取得して array の hashで返す
  def self.get_news_hash_array(bot_id)
    result = []
    NewsFeed.where(:bot_id => bot_id).each_with_index do |nf,i|
      begin
        rss = RSS::Parser.parse(nf.url)
        rss.items.each{|item|
          Rails.logger.debug("item.title=#{item.title}")
          Rails.logger.debug("item.link=#{item.link}")
          Rails.logger.debug("item.description=#{item.description}")
#          Rails.logger.debug("item.=#{item.inspect}")
#          Rails.logger.debug("img url=#{get_img(item.link).inspect}")
          result << {
            :nf_title => nf.title,
            :title => item.title,
            :link => item.link,
            :desc => item.description,
            :dt => item.pubDate.strftime("%Y-%m-%d %H:%M:%S")
          }
        }
      rescue => e
        Rails.logger.error(e)
      end
    end
    return result
  end

  # 画像は厳しそう 一旦なし 
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
