
get '/settings' do
  redirect "/settings/account"
end

[ "account", "editing", "notifications" ].each { |domain|
  get "/settings/#{domain}", auth: :user do
    current_page("manage")

    erb :"/users/settings/#{domain}"
  end
}

post '/settings/password', auth: :user do
  pw = Digest::SHA1.hexdigest(params[:password][:current])

  if current_user.password == pw then
    pw_new = Digest::SHA1.hexdigest(params[:password][:new])
    pw_confirm = Digest::SHA1.hexdigest(params[:password][:confirmation])

    if params[:password][:new].empty? then
      flash[:error] = "You've entered an empty password!"
    elsif pw_new == pw_confirm then
      current_user.password = pw_new
      if current_user.save then
        flash[:notice] = "Your password has been changed."
      else
        flash[:error] = "Something bad happened while updating your password!"
      end
    else
      flash[:error] = "The passwords you've entered do not match!"
    end
  else
    flash[:error] = "The current password you've entered isn't correct!"
  end

  redirect back
end

post '/settings/nickname', auth: :user do
  # see if the nickname is available
  nickname = params[:nickname]
  if nickname.empty? then
    flash[:error] = "A nickname can't be empty!"
    return redirect back
  end

  u = User.first(nickname: nickname)
  # is it taken?
  if u && u.email != current_user.email then
    flash[:error] = "That nickname isn't available. Please choose another one."
    return redirect back
  end

  current_user.nickname = nickname
  current_user.auto_nickname = false

  if current_user.save then
    flash[:notice] = "Your nickname has been changed."
  else
    flash[:error] = "Something bad happened while updating your nickname."
  end

  redirect back
end

post "/settings/profile", auth: :user do

  { :name => "Your name can not be empty",
    :email => "You must specify a primary email address.",
    :gravatar_email => "Your gravatar email address can not be empty."
  }.each_pair { |k, err|
    if !params[k] || params[k].empty?
      flash[:error] = err
      return redirect back
    else
      current_user.send("#{k}=".to_sym, params[k])
    end
  }

  if current_user.save then
    flash[:notice] = "Your profile has been updated."
  else
    flash[:error] = current_user.collect_errors
  end

  redirect back
end

get '/settings/verify/:type', auth: :user do |type|
  dispatcher = lambda { |addr, tmpl|
    Pony.mail :to => addr,
              :from => "noreply@#{AppURL}",
              :subject => "[#{AppName}] Please verify your email '#{addr}'",
              :html_body => erb(tmpl.to_sym, layout: "layouts/mail".to_sym)
  }

  # was a notice already issued and another is requested?
  redispatch = params[:redispatch]

  @type       = type       # useful in the view
  @redispatch = redispatch # useful in the view

  case type
  when "email"
    if current_user.email_verified?
      return erb :"/emails/already_verified"
    end

    if redispatch
      current_user.notices.all({ type: 'email' }).destroy
    else # no re-dispatch requested

      # notice already sent and is pending?
      if current_user.awaiting_email_verification?
        return erb :"/emails/already_dispatched"
      end
    end

    unless @n = current_user.verify_email
      halt 500, "Unable to generate a verification link: #{current_user.collect_errors}"
    end

    dispatched = false
    error_msg = ''

    begin
      dispatched = dispatcher.call(current_user.email, "emails/verification")
    rescue Exception => e
      dispatched = false
      error_msg = e.message
    end

    # remove the notice, the mail wasn't delivered
    unless dispatched
      current_user.notices.all({ type: 'email' }).destroy
      if error_msg.empty?
        halt 500, "Mail could not be delivered, please try again later."
      else
        halt 500, "Mail could not be delivered: '#{error_msg}'"
      end
    end

  else # an unknown type
    halt 400, "Unrecognized verification parameter '#{type}'."
  end

  erb :"/emails/dispatched"
end
