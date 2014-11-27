class Api::V1::AuthenticationsController < Api::V1::BaseController

  skip_authorization_check
  include ApplicationHelper
  # def new
  #   session[:api_client_id] = '1234567890'
  #   session[:last_url] = params[:redirect_url]
  #   redirect_to "/auth/#{params[:provider]}"
  # end

  # =begin apidoc
  # url:: GET - /api/v1/authenticae/create (200)
  # method:: GET
  # access:: FREE
  # return:: [JSON] - Created user and success message or failure message if failed.
  # param:: omniauth[uid]:string - Social network ID  - Require
  # param:: omniauth[provider]:String - facebook Or twitter - Require
  # param:: omniauth[credentials][token]  - Require
  # param:: omniauth[credentials][secret] - Not Require
  # param:: omniauth[info][email] - Require
  # param:: omniauth[info][name] - Require
  # param:: omniauth[info][image] - Not Require  
  # output:: json
  # {
  #   "success":true,
  #   "user":{
  #     "api_token":"XarXyKwV1tLx4S3qsKcY",
  #     "email":"zzsaz@hhh.com",
  #     "id":22,
  #     "name":"mohamed",
  #     "like_count":0,
  #     "avatar_url":null,
  #     "permissions":{
  #       "manage":false,
  #       "read":true,
  #       "create":true,
  #       "update":false,
  #       "destroy":false
  #     }
  #   }
  # }
  # ::output-end::
  #
  # Sign in and Sign up through social network.
  # =end

  # =begin apidoc
  # url:: GET - /api/v1/authenticae/create (401)
  # method:: GET
  # access:: FREE
  # return:: [JSON] - Faiure messgae.
  # param:: omniauth[uid]:string - Social network ID
  # param:: omniauth[provider]:String - facebook Or twitter
  # param:: omniauth[credentials][token] 
  # param:: omniauth[credentials][secret]
  # param:: omniauth[info][email]
  # param:: omniauth[info][name]
  # param:: omniauth[info][image]
  # param:: omniauth[info][terms]
  # output:: json
  # {
  #   "success":false,
  #   "message":"Error with social login"
  # }
  # ::output-end::
  #
  # Sign in and Sign up through social network.
  # =end
  def create
    omniauth = params[:omniauth]
    @user, @authentication = User.by_omniauth(omniauth, current_user)
    if @user.persisted?
      session[:user_id] = @user.id
      render :json=> {:success=>true, :user=>{:api_token=>@user.authentication_token, :email=>@user.email, :id=>@user.id, :name=>@user.name, :like_count=>@user.like_count,:avatar_url=> @user.avatar_url, :permissions=> permissions(@user)}}
      return
    end
    render :json=> {:success=>false, :message=>"Error with social login", :errors=>@user.errors}, :status=>401
  end

end