class RssapiController < ApiController
  
  # 現在時でニュース作成
  def create_news_by_bot_id(bot_id, ymdh)
    
    # news array
    news = NewsFeed.get_news_hash_array(bot_id)
    
    # ニュース保存
    Attr.save(bot_id, ymdh, 1, 0, news.to_s)
  end

  #  現在日時の指定noのニュースを配信
  # last_no = 最終配信no
  def send_news_by_botid_nextno(bot_id, event, next_no)
    ymdh = DateTime.now.strftime("%Y%m%d%H")
    
    attr = Attr.get(bot_id, ymdh, 1) # 記事データ
    if attr.blank?
      create_news_by_bot_id(bot_id, ymdh) # ニュースがなければ再構築
      attr = Attr.get(bot_id, ymdh, 1)  # 再取得
      next_no = 0 # 先頭から
    end
    
    send_feed_all = eval(attr.text) # 送信対象 TODO 最後チェック
    
    # next_no が配列の範囲内であること
    next_no = send_feed_all.count - 1 if next_no < 0
    next_no = 0 if next_no >= send_feed_all.count
    send_feed = send_feed_all[next_no]
    
    Rails.logger.debug("send_feed = #{send_feed}")
    Rails.logger.debug("send_feed = #{send_feed.inspect}")
    
    if send_feed.blank?
      return [{ type: 'text', text: "現在配信準備中です。"}]
    end

    # 最後に配信した時間_userごとに 配信noを保存 > 不要か
#    Attr.save(2, "#{ymd}_#{event['source']['userId']}", 2, next_no, "")    
    
    # 本文
    begin
      
    text = "「#{send_feed[:title]}」
#{send_feed[:desc]}
#{send_feed[:nf_title]} - #{view_context.time_ago_in_words(DateTime.parse(send_feed[:dt]))}前"
    text = text.truncate(230, :omission => "...")
    
    # 送信実行 仮
    return [
      # コメント付版は別途開発かも
      # {
            # type: 'text',
            # text: "コメント1"
      # },
      # {
            # type: 'text',
            # text: "コメント2"
      # },
      # {
            # type: 'text',
            # text: "コメント3"
      # },
      # {
            # type: 'text',
            # text: "コメント4"
      # },
      # 操作配信 TODO 引用元
      {
        "type": "template",
        "altText": send_feed[:title],
        "template": {
            "type": "confirm",
            "text": text,
            "actions": [
                {
                  "type": "postback",
                  "label": "前へ",
                  "text": "前へ",
                  "data": {:next_no => (next_no-1).to_s, :ymdh => ymdh}.to_s
                },
                {
                  "type": "uri",
                  "label": "読む",
                  "uri": send_feed[:link]
                },
                {
                  "type": "postback",
                  "label": "次へ",
                  "text": "次へ",
                  "data": {:next_no => (next_no+1).to_s, :ymdh => ymdh}.to_s
                }
            ]
        }
      }
    ]
    
    rescue => e
      Rails.logger.error(e)
    end
  end
end
