#

# @author
#
class LineUser < ActiveRecord::Base
  
  # 常にinsertする
  def self.insert(bot_id, mid)
    LineUser.find_or_create_by(bot_id: bot_id, mid: mid) do |user|
    end
  end
  
end
