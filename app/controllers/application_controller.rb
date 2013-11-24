class ApplicationController < ActionController::Base
  protect_from_forgery
  def authenticate_user
    auth_token = cookies[:auth]

    return if !auth_token and controller_name == "home"
    redirect_to '/' if !auth_token

    uid = ApiClient.redis_get("auth:#{auth_token}")
    saved_auth_token = $redis.get("uid:#{uid}:auth")

    return if saved_auth_token != auth_token and controller_name == "home"
    redirect_to '/' if saved_auth_token != auth_token

    redirect_to '/account/dashboard' if controller_name == "home"
    @user_details = ApiClient.redis_hgetall("uid:#{uid}:details")
    cookies[:auth] = { :value => auth_token, :expires => 1.hour.from_now }

  end
end
