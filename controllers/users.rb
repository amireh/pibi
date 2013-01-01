require 'json'
require 'uuid'
require 'base64'

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

get '/users/new' do
  current_page("signup")
  erb :"/users/new"
end

post '/users' do
  p = params

  # Validate input
  {
    "That email is already registered" => User.first(email: p[:email]),
    "You must fill in your email address" => !p[:email] || p[:email].empty?,
    "That email doesn't appear to be valid" => !p[:email].is_email?,
    "You must fill in your name" => !p[:name] || p[:name].empty?,
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
  params[:password] = User.encrypt(params[:password])

  nickname = params[:name].to_s.sanitize
  auto_nn = false
  if User.first({ nickname: nickname }) then
    nickname = "#{nickname}_#{nickname_salt}"
    auto_nn = true
  end

  params.delete("password_confirmation")

  # Create the user with a UUID
  unless u = User.create(params.merge({
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

get '/users/:id/accept/:token', auth: :user do |uid, token|
  unless @n = @scope.notices.first({ salt: token })
    halt 400, "No such verification link."
  end

  case @n.status
  when :expired
    return erb :"emails/expired"

  when :accepted
    case @n.type
    when 'email'
      flash[:error] = "This verification notice seems to have been accepted earlier."
    end

    return redirect "/settings/account"

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