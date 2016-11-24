#

# @author
#
class LineUser < ActiveRecord::Base
  
  # 常にinsertする
  def self.insert(bot_id, event)
    mid = nil
    type = event['source']['type']
    mid = event['source']['userId'] if type == 'user'
    mid = event['source']['groupId'] if type == 'group'
    mid = event['source']['roomId'] if type == 'room'
    LineUser.find_or_create_by(bot_id: bot_id, source_type: type, mid: mid) do |user|
    end
  end
  
end
