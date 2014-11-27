class Api::V1::BaseController < ApplicationController
  skip_before_filter :set_last_url
  before_filter :set_default_response_format
  # after_filter :set_pagination_headers
  respond_to :js, :json#, :html

  check_authorization

  rescue_from ::ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ::CanCan::AccessDenied, with: :unauthorized_access
  rescue_from ::NameError, with: :error_occurred
  # rescue_from ::ActionController::RoutingError, with: :error_occurred
  # rescue_from ::Exception, with: :error_occurred

  protected
  def record_not_found(exception)
    render json: {message: exception.message}.to_json, status: 404
    return
  end

  def error_occurred(exception)
    render json: {message: exception.message}.to_json, status: 500
    return
  end

  def authenticate_api_user!
    unless current_user
      token = nil
      if request.headers["Authorization"].present?
        token = request.headers["Authorization"]
      elsif params[:_token].present?
        token = params[:_token]
      end
      if token.present?
        authentication = User.find_by_authentication_token(token)
      end
      if authentication.present?
        session[:user_id] = authentication.id
      else
        unauthorized_access
      end
    end
  end

  def set_default_response_format
    request.format = :json if params[:format].blank?
    # raise "request.referrer: #{request.referrer.inspect}"
    # response.headers['Access-Control-Allow-Origin'] = request.referrer
    response.headers['Access-Control-Allow-Origin'] = "*"
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'x-requested-with, x-requested-by, Authorization'
  end

  def unauthorized_access
    render json: {message: "You must be an authenticated user to access this API!"}.to_json, status: 401
  end
  
  def current_user
    @current_user = super
    unless @current_user
      if session[:user_id].present?
        @current_user = User.find(session[:user_id])
      end
    end
    return @current_user
  end
  def is_numeric?(i)
    i.to_i.to_s == i #|| i.to_f.to_s == i   only integer needed here 
  end

  def order_by_location(arr, options = {})
    return arr unless arr
    lat = options[:lat].to_f
    lng = options[:lng].to_f
    if options[:location].present?# && options[:lat].blank? || options[:lng].blank?
      res = Geocoder.coordinates(options[:location])
      if res.present?
        lat = res.first
        lng = res.last
      end
    end
    user_location = {lat: lat, lng: lng}
    arr.sort{|point1, point2| near(point1, point2, user_location)}
  end

  private
  def near(point1, point2, origin)
    return 0 if ((point1.lat.blank? || point1.lng.blank?) && (point2.lat.blank? || point2.lng.blank?))
    return 1 if ((point1.lat.blank? || point1.lng.blank?) && (point2.lat.present? && point2.lng.present?))
    return -1 if ((point1.lat.present? && point1.lng.present?) && (point2.lat.blank? || point2.lng.blank?))

    distance1 = Math.hypot(origin[:lat]-point1.lat,origin[:lng]-point1.lng)
    distance2 = Math.hypot(origin[:lat]-point2.lat,origin[:lng]-point2.lng)
    return distance1 - distance2
  end
end
