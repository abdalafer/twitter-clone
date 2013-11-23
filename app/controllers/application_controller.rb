class ApplicationController < ActionController::Base
  protect_from_forgery
  def authenticate_user
    redirect_to '/' if !cookies[:auth]
    auth_token = cookies[:auth]
    uid = ApiClient.redis_get("auth:#{auth_token}")

    if uid == ApiClient.redis_get("auth:#{auth_token}")
      redirect_to '/' if $redis.get("uid:#{uid}:auth") != auth_token
      @user_details = ApiClient.redis_hgetall("uid:#{uid}:details")
      cookies[:auth] = { :value => auth_token, :expires => 1.hour.from_now }
    end


  end
end
