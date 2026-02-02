class SessionsController < ApplicationController
  before_action :ensure_development_env

  def new
    @users = User.order(:role, :email_hmac)
  end

  def create
    user = User.find(params[:user_id])
    session[:user_id] = user.id
    redirect_to root_path, notice: "Logged in as #{user.role} user."
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Logged out."
  end

  private

  def ensure_development_env
    unless Rails.env.development? || Rails.env.test?
      redirect_to root_path, alert: "Not authorized."
    end
  end
end
