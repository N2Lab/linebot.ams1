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
