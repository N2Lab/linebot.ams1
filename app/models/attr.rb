#

# @author
#
class Attr < ActiveRecord::Base
  
  def self.get(bot_id, mid, no)
    Attr.where(:bot_id => bot_id, :mid => mid, :no => no).first
  end
  
  def self.create(bot_id, mid, no, val, text)
    obj = Attr.find_or_initialize_by(bot_id: bot_id, mid: mid, no: no) # uid = 'sample' のユーザが存在する場合は取得、しなければ新規作成(未保存)
    if obj.new_record? # 新規作成の場合は保存
      obj.val = val
      obj.text = text
      # 新規作成時に行いたい処理を記述
      obj.save!
    end
  end
  
  def self.save(bot_id, mid, no, val, text)
    obj = Attr.create(bot_id, mid, no, val, text)
    obj.update_attributes({
      :val => val,
      :text => text
    })
  end
  
end
