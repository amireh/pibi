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

  def restrict_to(roles, options = {})
    roles = [ roles ] if roles.is_a? Symbol

    if roles.include?(:active_user)
    #   restricted!
    #   @scope = current_user

    #   if current_user.locked?
    #     halt 403, "This action is for available to this account because it is locked."
    #   end

      # proceed to normal user auth
      roles << :user
    end

    if roles.include? :user || roles.include?(:admin)
      restricted!
      @scope = @user = current_user
      @account ||= @user.accounts.first

      if options[:with_id]
        unless @user.key.first == options[:with_id].to_i
          halt 403, "You do not have access to that user account."
        end
      end

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

  set(:auth) do |*roles|
    condition do
      restrict_to(roles)
    end
  end

  def current_user
    return @user if @user

    # disabled: locking & public accounts
    # if params[:public_uid]
    #   @user = User.first({ id: params[:public_uid], is_public: true })
    #   @account = @user.accounts.first
    #   return @user
    # end

    return nil unless session[:id]
    @user = User.get(session[:id])
  end

  def current_account
    # unless session[:account]
    #   session[:account] = current_user.accounts.first.id
    # end

    @account ||= current_user.accounts.first
  end

  def authorize(user)
    session[:id] = user.id
  end

end

helpers SessionsHelper