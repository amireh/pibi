get '/sessions/new' do
  current_page("signin")
  erb :"/sessions/new"
end

post '/sessions' do
  # validate address
  unless params[:email].is_email?
    flash[:error] = "The email address you entered seems to be invalid."
    return redirect '/sessions/new'
  end

  unless u = User.first({ email: params[:email], password: User.encrypt(params[:password]) })
    flash[:error] = "Incorrect email or password, please try again."
    return redirect '/sessions/new'
  end

  authorize(u)
  redirect '/'
end

delete '/sessions' do
  session[:id] = nil

  flash[:notice] = "Successfully logged out."
  redirect '/'
end

# Support both GET and POST for callbacks
%w(get post).each do |method|
  send(method, "/auth/:provider/callback") do |provider|
    if u = create_from_oauth(provider, env['omniauth.auth'])
      flash[:notice] = "Welcome to #{AppName}! You have successfully signed up using your #{provider.capitalize} account."
      authorize(u)
      redirect '/'
    else
      halt 500, "Sorry! Something wrong happened while signing you up using your #{provider.capitalize} account: #{u.collect_errors}"
    end
  end
end

get '/auth/failure' do
  flash[:error] = params[:message]
  redirect '/sessions/new'
end