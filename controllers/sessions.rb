get '/sessions/new' do
  current_page("signin")
  erb "/sessions/new".to_sym
end

post '/sessions' do
  pw = Digest::SHA1.hexdigest(params[:password])
  info = { password: pw }

  # authenticating using email?
  if params[:email].is_email? then
    info[:email] = params[:email]
  # or nickname?
  else
    info[:nickname] = params[:email]
  end

  unless u = User.first(info)
    flash[:error] = "Incorrect id or password, please try again."
    return redirect "/sessions/new"
  end

  session[:id] = u.id
  session[:account] = u.accounts.first.id
  redirect '/'
end

delete '/sessions' do
  session[:id] = nil
  session[:account] = nil

  flash[:notice] = "Successfully logged out."
  redirect '/'
end

# Support both GET and POST for callbacks
%w(get post).each do |method|
  send(method, "/auth/:provider/callback") do |provider|
    auth = env['omniauth.auth']

    # create the user if it's their first time
    unless u = User.first({ uid: auth.uid, provider: provider, name: auth.info.name })

      uparams = { uid: auth.uid, provider: provider, name: auth.info.name }
      uparams[:email] = auth.info.email if auth.info.email
      uparams[:nickname] = auth.info.nickname if auth.info.nickname
      uparams[:oauth_token] = auth.credentials.token if auth.credentials.token
      uparams[:oauth_secret] = auth.credentials.secret if auth.credentials.secret

      if auth.extra.raw_info then
        uparams[:extra] = auth.extra.raw_info.to_json.to_s
      end

      fix_nickname = false
      nickname = ""

      # Make sure the nickname isn't taken
      if uparams.has_key?(:nickname) then
        if User.first({ nickname: uparams[:nickname] }) then
          nickname = uparams[:nickname] # just add the salt to it
          fix_nickname = true
        end
      else
        # Assign a default nickname based on their name
        nickname = auth.info.name.to_s.sanitize
      end

      if fix_nickname
        uparams[:nickname] = "#{nickname}_#{nickname_salt}"
        uparams[:auto_nickname] = true
      end

      # puts "Creating a new user from #{provider} with params: \n#{uparams.inspect}"
      u = User.create(uparams)
      if u then
        flash[:notice] = "Welcome to #{AppName}! You have successfully signed up using your #{provider} account."

        session[:id] = u.id

        return redirect '/'
      else
        flash[:error] = "Sorry! Something wrong happened while signing you up. Please try again."
        return redirect "/auth/#{provider}"
      end
    end

    # puts "User seems to already exist: #{u.id}"
    session[:id] = u.id

    redirect '/'
  end
end

get '/auth/failure' do
  flash[:error] = params[:message]
  redirect '/'
end