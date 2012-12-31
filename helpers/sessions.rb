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
      if roles.include? :user || roles.include?(:admin)
        restricted!
        @scope = current_user
        @account ||= @user.accounts.first

        if params[:account] then
          unless @account = current_user.accounts.get(params[:account])
            halt 500, "No such account."
          end
        end

        if roles.include?(:admin) && !@scope.is_admin
          halt 403, "Admin privileges are needed to visit this section."
        end
      end
    end
  end

  def current_user
    return @user if @user
    return nil unless session[:id]

    @user = User.get(session[:id])
  end

  def current_account
    return @account if @account

    unless session[:account]
      session[:account] = current_user.accounts.first.id
    end

    @account = current_user.accounts.first({ id: session[:account] })
  end



end

helpers do
  include SessionsHelper
end