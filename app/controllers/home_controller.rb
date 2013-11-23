class HomeController < ApplicationController


  def index
    #todo, if logged in, redirect to dashbaord
    @login = Login.new
    render :layout => "layouts/outside"
  end

  def login
    @login = Login.new(params[:login])
    if @login.valid?
      auth_response = Account.login(params[:login]["username"], params[:login]["password"])
      if auth_response
        cookies[:auth] = { :value => auth_response, :expires => 1.hour.from_now }
        redirect_to "/account/dashboard"
      else
        flash[:wrong_credentials] = "Bad username or password"
        render :action => "index", :layout => "layouts/outside"
      end
    else
      render :action => "index", :layout => "layouts/outside"
    end
  end

end
