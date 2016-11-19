require 'httpclient'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token
  
  def get_profile(client, user_id)
    response = client.get_profile(user_id)
    JSON.parse(response.body)
  end
  
  
  def  make_template_buttons_message(title, text, url, actions)
      {
        type: "template",
        altText: text,
        template: {
            type: "buttons",
            thumbnailImageUrl: url,
            title: title,
            text: text,
            actions: actions
        }
      }      
  end
  
  # 1. call Google Cloud Natural Language API and parse
  #  language.documents.analyzeEntities = Entities（固有表現抽出）
  # doc https://cloud.google.com/natural-language/reference/rest/v1/documents/analyzeEntities
  # text ex) 明日渋谷駅ハチ公前で9時ね！時間厳守で！
  # @return ex)
# {
 # "entities": [ # The recognized entities in the input document.  https://cloud.google.com/natural-language/reference/rest/v1/Entity
  # {
   # "name": "明日渋谷駅", # entityname The representative name for the entity.
   # "type": "LOCATION", # 名前のタイプ
   # "metadata": {
   # },
   # "salience": 0, # 重要度/突出率? 0-1.0 The salience score associated with the entity in the [0, 1.0] range.
   # "mentions": [ # 補足? The mentions of this entity in the input document. The API currently supports proper noun mentions.
    # {
     # "text": { # https://cloud.google.com/natural-language/reference/rest/v1/TextSpan
      # "content": "明日渋谷駅", 
      # "beginOffset": 0 # 元テキストの位置
     # },
     # "type": "PROPER" # TYPE_UNKNOWN, PROPER(固有名?), COMMON(公的?)
    # }
   # ]
  # },
  # {
   # "name": "ハチ公",
   # "type": "CONSUMER_GOOD",
   # "metadata": {
   #   "mid" => "/m02mjmr"  graph mid 詳細不明
   #   "wikipedia_url" => "http://xxx"   wikipedia url
   # },
   # "salience": 0,
   # "mentions": [
    # {
     # "text": {
      # "content": "ハチ公",
      # "beginOffset": 15
     # },
     # "type": "COMMON"
    # }
   # ]
  # },
  # {
   # "name": "時間厳守",
   # "type": "OTHER",
   # "metadata": {
   # },
   # "salience": 0,
   # "mentions": [
    # {
     # "text": {
      # "content": "時間厳守",
      # "beginOffset": 41
     # },
     # "type": "COMMON"
    # }
   # ]
  # }
 # ],
 # "language": "ja"
# }  

# type
# UNKNOWN Unknown
# PERSON  Person
# LOCATION  Location
# ORGANIZATION  Organization
# EVENT Event
# WORK_OF_ART Work of art  芸術作品
# CONSUMER_GOOD Consumer goods  商品
# OTHER Other types  キャラクター名とか
  def google_api_natural_lang_entities(key, text)
    url = "https://language.googleapis.com/v1/documents:analyzeEntities?key=#{key}"
    params = {
      :document => {
        :type => "PLAIN_TEXT",
        :language => "ja",
        :content => text
      },
      :encodingType => "UTF8",
    }
    c = HTTPClient.new
    res = c.post_content(url, params.to_json, 'Content-Type' => 'application/json')
    hash = JSON.parse(res)
    
    Rails.logger.debug("[analyzeEntities request url] #{url}")
    Rails.logger.debug("[analyzeEntities request req] #{params}")
    Rails.logger.debug("[analyzeEntities request res] #{hash}")
    hash
    
  end

end
