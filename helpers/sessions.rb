module SessionsHelper

  def logged_in?
    !current_user.nil?
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

        if params[:account] then
          unless @account = current_user.accounts.get(params[:account])
            halt 500, "No such account."
          end
        end
      end
    end
  end

  def current_user
    return @user if @user
    return nil unless session[:id]

    @user = User.get(session[:id])
  end

end

helpers do
  include SessionsHelper
end