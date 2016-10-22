class ApiController < ApplicationController

  skip_before_action :verify_authenticity_token
  
  # LINE絵文字コードを文字に変換する
  # 使用例  em(0x10006C)
  def em(code)
    [ code ].pack( "U*" )
  end
end
