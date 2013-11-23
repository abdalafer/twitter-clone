class AccountController < ApplicationController
  before_filter :authenticate_user, :except => [:new, :create, :login]

  def new
    @account = Account.new
    render :layout => "layouts/outside"
  end

  def create
    @account = Account.new(params[:account])
    if @account.valid?
      @account.create
      redirect_to("/account/dashboard")
    else
      render :action => "new", :layout => "layouts/outside"
    end
  end

  def logout
    auth_token = cookies[:auth]
    Account.logout(auth_token)
    redirect_to '/'
  end

  def dashboard
    @tweet = Tweet.new
  end

  def user_summary
    @user_summary  = Account.user_summary(params[:id])
    render :json => {
        :html => render_to_string({:partial => 'account/user_summary'}), :locals =>  @user_summary  }
  end

  def tweet_box
    tweet = Tweet.new
    tweet.uid = @user_details["uid"]
    @all_tweets = tweet.get_all_tweets

    render :json => {
        :html => render_to_string({:partial => 'account/tweet_box'}), :locals =>  @all_tweets  }
  end

  def tweet
    @tweet = Tweet.new(params[:tweet])
    @tweet.uid = @user_details['uid']
    @tweet.username = @user_details['username']
    @tweet.tweet

    if @tweet
      redirect_to "/account/dashboard"
    end
  end

  def follow
    user_to_follow = params[:id]
    Account.follow @user_details["uid"], user_to_follow

    #render success
    render :json => {"message" => "success"}, :status => 200
  end

  def unfollow
    followed_uid = params[:id]
    Account.unfollow @user_details["uid"], followed_uid

    #render success
    render :json => {"message" => "success"}, :status => 200
  end

  def show_all
  end

  def show_all_users
    @all_users = Account.show_all_users @user_details["uid"]
    render :json => {
        :html => render_to_string({:partial => 'account/all_users'}), :locals =>  @all_users  }
  end

  def show_following_users
    @following = Account.show_following_users @user_details["uid"]
    render :json => {
        :html => render_to_string({:partial => 'account/following_users'}), :locals =>  @following  }
  end

  def search
    @search_hits = Account.search(params[:query])
  end

end
