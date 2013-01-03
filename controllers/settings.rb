namespace '/settings' do
  condition do
    restrict_to(:user)
  end

  before do
    current_page("manage")
  end

  [ "account", "notifications", "preferences", 'password' ].each { |domain|
    get "/#{domain}" do
      @standalone = true

      erb :"/users/settings/#{domain}"
    end
  }

  post '/preferences' do
    notices = []
    errors  = []

    if params[:payment_method] && !params[:payment_method][:name].empty?
      new_pm = @user.payment_methods.create({ name: params[:payment_method][:name] })
      if new_pm.saved?
        notices << "The payment method '#{new_pm.name}' has been registered successfully."
      else
        errors << new_pm.all_errors
      end
    end

    # update the user's default payment method
    if params[:default_payment_method]
      if @user.payment_method.id != params[:default_payment_method].to_i
        @user.payment_method = @user.payment_methods.get(params[:default_payment_method].to_i)
        if @user.save
          notices << "The default payment method now is '#{@user.payment_method.name}'"
        else
          errors << @user.all_errors
        end
      end
    end

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

    flash[:error]  = errors.flatten unless errors.empty?
    flash[:notice] = notices.flatten unless notices.empty?

    redirect back
  end

  delete '/preferences/payment_methods/:pm_id' do |pm_id|
    unless pm = current_user.payment_methods.get(pm_id)
      halt 400, "No such payment method '#{pm_id}'."
    end

    notices = []

    was_default = pm.default
    its_name    = pm.name

    if pm.destroy
      notices << "The payment method '#{its_name}' has been removed."
    else
      flash[:error] = pm.all_errors
      return redirect back
    end

    if was_default
      if current_user.payment_methods.empty?
        current_user.payment_methods.create({ name: "Cash", default: true })
      else
        pm = current_user.payment_methods.first
        pm.update({ default: true })
      end

      notices << "#{@user.payment_method.name} is now your default payment method."
    end

    flash[:notice] = notices

    redirect back
  end

  post '/password' do

    pw = User.encrypt(params[:password][:current])

    if current_user.password != pw then
      flash[:error] = "The current password you've entered isn't correct!"
      return redirect back
    end

    # validate length
    # we can't do it in the model because it gets the encrypted version
    # which will always be longer than 8
    if params[:password][:new].length < 7
      flash[:error] = "That password is too short, it must be at least 7 characters long."
      return redirect back
    end

    back_url = back

    @user.password              = User.encrypt(params[:password][:new])
    @user.password_confirmation = User.encrypt(params[:password][:confirmation])

    if current_user.save then
      notices = current_user.pending_notices({ type: 'password' })
      unless notices.empty?
        back_url = "/"
        notices.each { |n| n.accept! }
      end
      flash[:notice] = "Your password has been changed."
    else
      flash[:error] = @user.all_errors
    end

    redirect back_url
  end

  post "/account" do
    if current_user.update({
      name: params[:name],
      email: params[:email],
      gravatar_email: params[:gravatar_email] }) then
      flash[:notice] = "Your account info has been updated."
    else
      flash[:error] = current_user.all_errors
    end

    redirect back
  end

end


