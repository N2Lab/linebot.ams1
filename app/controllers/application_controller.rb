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

  // 
  def save_user(bot_id, event)
    LineUser.insert(bot_id, event)
  end

  def groop_or_room?(event)
    source_type = event["source"]['type']
    ["group", "room"].include?(source_type)
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

  # google Places API Web Service 検索
  def google_api_places_search_text(key, text)
    url = "https://maps.googleapis.com/maps/api/place/textsearch/json?key=#{key}&query=#{url_encode(text)}"
    c = HTTPClient.new
    res = c.get_content(url)
    hash = JSON.parse(res)
    
    Rails.logger.debug("[google_api_places_search_text request url] #{url}")
    Rails.logger.debug("[google_api_places_search_text request res] #{hash}")

# response
# {
#    "html_attributions" : [],
#    "results" : [
#       {
#          "geometry" : {
#             "location" : {
#                "lat" : -33.870775,
#                "lng" : 151.199025
#             }
#          },
#          "icon" : "http://maps.gstatic.com/mapfiles/place_api/icons/travel_agent-71.png",
#          "id" : "21a0b251c9b8392186142c798263e289fe45b4aa",
#          "name" : "Rhythmboat Cruises",
#          "opening_hours" : {
#             "open_now" : true
#          },
#          "photos" : [
#             {
#                "height" : 270,
#                "html_attributions" : [],
#                "photo_reference" : "CnRnAAAAF-LjFR1ZV93eawe1cU_3QNMCNmaGkowY7CnOf-kcNmPhNnPEG9W979jOuJJ1sGr75rhD5hqKzjD8vbMbSsRnq_Ni3ZIGfY6hKWmsOf3qHKJInkm4h55lzvLAXJVc-Rr4kI9O1tmIblblUpg2oqoq8RIQRMQJhFsTr5s9haxQ07EQHxoUO0ICubVFGYfJiMUPor1GnIWb5i8",
#                "width" : 519
#             }
#          ],
#          "place_id" : "ChIJyWEHuEmuEmsRm9hTkapTCrk",
#          "scope" : "GOOGLE",
#          "alt_ids" : [
#             {
#                "place_id" : "D9iJyWEHuEmuEmsRm9hTkapTCrk",
#                "scope" : "APP"
#             }
#          ],
#          "reference" : "CoQBdQAAAFSiijw5-cAV68xdf2O18pKIZ0seJh03u9h9wk_lEdG-cP1dWvp_QGS4SNCBMk_fB06YRsfMrNkINtPez22p5lRIlj5ty_HmcNwcl6GZXbD2RdXsVfLYlQwnZQcnu7ihkjZp_2gk1-fWXql3GQ8-1BEGwgCxG-eaSnIJIBPuIpihEhAY1WYdxPvOWsPnb2-nGb6QGhTipN0lgaLpQTnkcMeAIEvCsSa0Ww",
#          "types" : [ "travel_agency", "restaurant", "food", "establishment" ],
#          "vicinity" : "Pyrmont Bay Wharf Darling Dr, Sydney"
#       },    
    hash
    
  end

  # イベントが room or group からか
  def group_or_room_event?(event)
    source_type = event["source"]['type']
    ["group", "room"].include?(source_type) 
  end

  # 現在リクエストがあったgroup_roomから退会
  # 
  # @param event
  # @param client
  def leave_group_or_room(client, event)
    source_type = event["source"]['type']
    if ("group" == source_type) 
      client.leave_group(event["source"]['groupId'])
    else
      client.leave_room(event["source"]['roomId'])
    end
  end

end
