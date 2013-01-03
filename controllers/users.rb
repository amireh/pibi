after do
  if current_user
    if response.status == 200
      if current_user.auto_password && request.path != '/settings/password'
        # return erb :"/users/settings/password"
        flash.keep
        return redirect '/settings/password'
      end
    end
  end
end

before do

  # handle any invalid states we need to notify the user of
  if current_user
    messages = [] # see below

    unless current_user.email_verified?

      # send an email verification email unless one has already been sent
      unless current_user.awaiting_email_verification?
        if @n = current_user.verify_email
          dispatch_email_verification(current_user)
        end
      end

      @n = current_user.pending_notices({ type: 'email' }).first
      unless @n.displayed
        m = 'Your email address is not yet verified. ' <<
            'Please check your email, or visit <a href="/settings/account">this page</a> for more info.'
        messages << m

        @n.update({ displayed: true })
      end
    end

    if current_user.auto_password
      # has an auto password and the code hasn't been sent yet?
      if current_user.pending_notices({ type: 'password' }).empty?
        @n = current_user.generate_temporary_password
        dispatch_temp_password(current_user)
      end
    end

    # this has to be done because for some reason the flash[] doesn't persist
    # in order to append to it, so doing something like the following FAILS:
    # => flash[:warning] = []
    # => flash[:warning] << 'some message'
    unless messages.empty?
      flash[:warning] = messages
    end
  end
end

namespace '/users' do

  get '/new' do
    current_page("signup")
    erb :"/users/new"
  end

  def create_from_oauth(provider, auth)
    # create the user if it's their first time
    unless u = User.first({ uid: auth.uid, provider: provider })
      uparams = { uid: auth.uid, provider: provider, name: auth.info.name }
      uparams[:email] = auth.info.email if auth.info.email
      uparams[:oauth_token] = auth.credentials.token if auth.credentials.token
      uparams[:oauth_secret] = auth.credentials.secret if auth.credentials.secret
      uparams[:password] = uparams[:password_confirmation] = User.encrypt(Pibi::salt)
      uparams[:auto_password] = true

      if auth.extra.raw_info then
        uparams[:extra] = auth.extra.raw_info.to_json.to_s
      end

      # puts "Creating a new user from #{provider} with params: \n#{uparams.inspect}"
      u = User.create(uparams)
    end

    u
  end

  def build_from_pibi()
    u = User.new(params.merge({
      uid:      UUID.generate,
      provider: "pibi"
    }))

    if u.valid?
      u.password = User.encrypt(params[:password])
      u.password_confirmation = User.encrypt(params[:password_confirmation])
    end

    u
  end

  post do
    u = create_from_pibi
    unless u.save || u.saved?
      flash[:error] = u.all_errors
      return redirect back
    end

    flash[:notice] = "Welcome to #{AppName}! Your new personal account has been registered."

    authorize(u)

    redirect '/'
  end
end

namespace '/users/:user_id' do |user_id|
  condition do
    restrict_to(:user, :with_id => params[:user_id])
  end

  before do current_page("manage") end

  get '/accept/:token' do |token|
    unless @n = @scope.notices.first({ salt: token })
      halt 400, "No such verification link."
    end

    case @n.status
    when :expired
      return erb :"emails/expired"
    when :accepted
      flash[:error] = "This verification notice seems to have been accepted earlier."
      return redirect "/settings/notifications"
    else
      @n.accept!
      case @n.type
      when 'email'
        flash[:notice] = "Your email address '#{@n.user.email}' has been verified."
        return redirect "/settings/account"
      when 'password'
        return redirect "/settings/account"
      end
    end
  end

  namespace '/settings' do
    [ "account", "notifications", "preferences", 'password' ].each { |domain|
      get "/#{domain}" do
        @standalone = true

        erb :"/users/settings/#{domain}"
      end
    }

    post '/preferences' do
      notices = []
      errors  = []

      if params[:payment_method] && !params[:payment_method].empty?
        new_pm = @user.payment_methods.create({ name: params[:payment_method] })
        if new_pm.saved?
          notices << "The payment method '#{pm.name}' has been registered successfully."
        else
          errors << new_pm.all_errors
        end
      end

      # update the user's default payment method
      if params[:default_payment_method]
        @user.payment_method = @user.payment_methods.get(params[:default_payment_method].to_i)
        if @user.save
          notices << "The default payment method now is '#{@user.payment_method.name}'"
        else
          errors << @user.all_errors
        end
      end

      # possibly_new_default_pm = current_user.payment_methods.first({ id: params[:payment_method] })
      # if possibly_new_default_pm && possibly_new_default_pm.id != current_user.payment_method.id
      #   success = true
      #   success = success && current_user.payment_method.update({ default: false })
      #   success = success && possibly_new_default_pm.update({ default: true })

      #   if success
      #   else
      #   end

      # end

      # update the account default currency
      if @account.currency != params[:currency]
        if @account.update({ currency: params[:currency] })
          notices << "The default account currency now is '#{@account.currency}'"
        else
          errors << @account.all_errors
        end
      end

      # update the payment method colors
      params["pm_colors"].each_pair { |pm_id, color|
        pm = @user.payment_methods.get(pm_id)
        if pm && pm.color != color
          pm.update({ color: color })
        end
      }

      flash[:error]  = errors unless errors.empty?
      flash[:notice] = notices unless notices.empty?

      redirect back
    end
  end
end