module SessionsHelper

  def logged_in?
    session[:id]
  end

  def restricted
    unless logged_in?
      flash[:error] = "You must sign in first."
      redirect "/", 303
    end
  end

  def restricted!(scope = nil)
    halt 401, "You must sign in first." unless logged_in?
  end

  set(:auth) do |*roles|
    condition do
      if roles.include? :user
        restricted!
        @scope = current_user
      end
    end
  end

  def current_user
    return @user if @user
    return nil unless logged_in?

    @user = User.get(session[:id])
  end

end

helpers do
  include SessionsHelper
end