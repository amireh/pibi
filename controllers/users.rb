require 'json'
require 'uuid'

private

ReservedNames = [ 'name', 'pibi' ]

def name_available?(name)
  nn = name.to_s.sanitize
  !name.empty? && !ReservedNames.include?(nn) && User.first(nickname: nn).nil?
end

def nickname_salt
  Base64.urlsafe_encode64(Random.rand(12345 * 1000).to_s)
end

public

before do
  if current_user && current_user.auto_nickname && flash.empty?
    flash[:notice] = "You have an auto-generated nickname, please go to your profile page and update it."
  end
end

get '/users/new' do
  erb :"/users/new"
end

post '/users' do
  p = params

  # Validate input
  {
    "That email is already registered" => User.first(email: p[:email]),
    "You must fill in your name" => !p[:name] || p[:name].empty?,
    "You must fill in your email address" => !p[:email] || p[:email].empty?,
    "That email doesn't appear to be valid" => !p[:email].is_email?,
    "You must type the same password twice" => p[:password].empty? || p[:password_confirmation].empty?,
    "The passwords you entered do not match" => p[:password] != p[:password_confirmation],
    "Passwords must be at least 5 characters long." => p[:password].length <= 4
  }.each_pair { |msg, cnd|
    if cnd then
      flash[:error] = msg
      return redirect back
    end
  }

  # Encrypt the password
  params[:password] = Digest::SHA1.hexdigest(params[:password])

  nickname = params[:name].to_s.sanitize
  auto_nn = false
  if User.first({ nickname: nickname }) then
    nickname = "#{nickname}_#{nickname_salt}"
    auto_nn = true
  end

  params.delete("password_confirmation")

  # Create the user with a UUID
  unless u = User.create!(params.merge({
    uid: UUID.generate,
    nickname: nickname,
    auto_nickname: auto_nn,
    provider: "pibi",
    email: params[:email] }))
    flash[:error] = "Something bad happened while creating your new account, please try again."
    return redirect back
  end

  flash[:notice] = "Welcome to #{AppName}! Your new personal account has been registered."
  session[:id] = u.id

  redirect '/'
end


get '/settings' do
  redirect "/settings/account"
end

[ "account", "editing", "notifications" ].each { |domain|
  get "/settings/#{domain}", auth: :user do
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
  dispatch = lambda { |addr, tmpl|
    Pony.mail :to => addr,
              :from => "noreply@#{AppURL}",
              :subject => "[#{AppName}] Please verify your email '#{addr}'",
              :html_body => erb(tmpl.to_sym, layout: "layouts/mail".to_sym)
  }

  redispatch = params[:redispatch]

  @type = type.to_sym

  case type
  when "primary"
    @address = current_user.email
    if !redispatch && current_user.verified?(@address)
      return erb :"/emails/already_verified"
    elsif !redispatch && current_user.awaiting_verification?(@address)
      return erb :"/emails/already_dispatched"
    else
      if redispatch
        current_user.email_verifications.first({ address: @address }).destroy
      end

      unless @ev = current_user.verify_address(@address)
        halt 500, "Unable to generate a verification link: #{current_user.collect_errors}"
      end

      dispatch.call(current_user.email, "emails/verification")
    end
  end

  erb :"/emails/dispatched"
end

get '/users/nickname' do
  restricted!
  nn = params[:nickname]

  return [].to_json if nn.empty?

  nicknames = []
  User.all(:nickname.like => "#{nn}%", limit: 10).each { |u|
    nicknames << u.nickname
  }
  nicknames.to_json
end

# Returns whether params[:nickname] is available or not
post '/users/nickname', auth: :user do
  name_available?(params[:nickname]).to_json
end

get '/users/:id/verify/:token', auth: :user do |uid, token|
  unless @ev = @scope.email_verifications.first({ salt: token })
    halt 400, "No such verification link."
  end

  if @ev.expired?
    return erb :"emails/expired"
  elsif @ev.verified?
    flash[:error] = "Your email address '#{@ev.address}' is already verified."
    return redirect "/settings/profile"
  else
    @ev.verify!
    flash[:notice] = "Your email address '#{@ev.address}' has been verified."
    return redirect "/settings/profile"
  end
end