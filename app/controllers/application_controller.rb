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
end
