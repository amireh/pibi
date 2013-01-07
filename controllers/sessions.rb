get '/sessions/new', auth: :guest do
  current_page("signin")
  erb :"/sessions/new"
end

post '/sessions', auth: :guest do
  # validate address
  unless params[:email].is_email?
    flash[:error] = "The email address you entered seems to be invalid."
    return redirect '/sessions/new'
  end

  unless u = User.first({
    email: params[:email],
    provider: 'pibi',
    password: User.encrypt(params[:password]) })
    flash[:error] = "Incorrect email or password, please try again."
    return redirect '/sessions/new'
  end

  authorize(u)
  redirect '/'
end

delete '/sessions', auth: :user do
  session[:id] = nil

  flash[:notice] = "Successfully logged out."
  redirect '/'
end

# Support both GET and POST for callbacks
%w(get post).each do |method|
  send(method, "/auth/:provider/callback") do |provider|
    u, new_user = create_user_from_oauth(provider, env['omniauth.auth'])

    if u.nil? || !u.saved?
      error_kind = new_user ? 'signing you up' : 'logging you in'
      halt 500,
        "Sorry! Something wrong happened while #{error_kind} using your #{provider_name provider}" +
        " account:<br /><br /> #{u.all_errors}"
    end

    # is the user logged in and attempting to link the account?
    if logged_in?
      if u.link_to(current_user)
        flash[:notice] = "Your #{provider_name(provider)} account is now linked to your #{provider_name(current_user)} one."
      else
        flash[:error] = "Linking to the #{provider_name(provider)} account failed: #{current_user.all_errors}"
      end

      return redirect back
    else
      # nope, a new user or has just logged in
      if new_user
        flash[:notice] = "Welcome to #{AppName}! You have successfully signed up using your #{provider_name(provider)} account."
      end

      # stamp the session as this new user
      authorize(u)
    end

    redirect '/'
  end
end

get '/auth/failure' do
  flash[:error] = "Sorry! Something wrong happened while authenticating: #{params[:message]}"
  redirect '/sessions/new'
end