module Sinatra
  module UsersController
    module Helpers
      def create_user_from_oauth(provider, auth)
        # create the user if it's their first time
        new_user = false
        unless u = User.first({ uid: auth.uid, provider: provider })
          puts auth.inspect

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
          new_user = true
          # create the user
          slave = User.create(uparams)

          # create a pibi user and link the provider-specific one to it
          master = build_user_from_pibi(uparams)
          master.save
          slave.link_to(master)

          u = master
        end

        [ u, new_user ]
      end

      def build_user_from_pibi(p = {})
        p = params if p.empty?
        u = User.new(p.merge({
          uid:      UUID.generate,
          provider: "pibi"
        }))

        if u.valid?
          u.password = User.encrypt(p[:password])
          u.password_confirmation = User.encrypt(p[:password_confirmation])
        end

        u
      end
    end # Helpers

    def self.registered(app)
      app.helpers UsersController::Helpers
    end
  end # UsersController

  register UsersController
end # Sinatra

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

      @n = current_user.pending_notices.first({ type: 'email' })
      unless @n.displayed
        m = 'Your email address is not yet verified. ' <<
            'Please check your email, or visit <a href="/settings/account">this page</a> for more info.'
        messages << m

        @n.update({ displayed: true })
      end

      unless @n.dispatched
        dispatch_email_verification(current_user)
      end
    end

    if current_user.auto_password
      # has an auto password and the code hasn't been sent yet?
      if current_user.pending_notices({ type: 'password' }).empty?
        @n = current_user.generate_temporary_password
        dispatch_temp_password(current_user)
      else
        @n = current_user.pending_notices.first({ type: 'password' })
        if !@n.dispatched
          dispatch_temp_password(current_user)
        end
      end
    end

    # this has to be done because for some reason the flash[] doesn't persist
    # in order to append to it, so doing something like the following FAILS:
    # => flash[:warning] = []
    # => flash[:warning] << 'some message'
    unless messages.empty?
      flash[:warning] = messages
    end
  end # if current_user
end

get '/users/new', auth: :guest  do
  current_page("signup")
  erb :"/users/new"
end

post '/users', auth: :guest do
  u = build_user_from_pibi
  if !u.valid? || !u.save || !u.saved?
    flash[:error] = u.all_errors
    return redirect '/users/new'
  end

  flash[:notice] = "Welcome to #{AppName}! Your new personal account has been registered."

  authorize(u)

  redirect '/'
end

delete '/users/links/:provider', auth: :user do |provider|

  if u = current_user.linked_to?(provider)
    if u.detach_from_master
      flash[:notice] = "Your current account is no longer linked to the #{provider_name(provider)} one" +
                       " with the email '#{u.email}'."
    else
      flash[:error] = "Unable to unlink accounts: #{u.all_errors}"
    end
  else
    flash[:error] = "Your current account is not linked to a #{provider_name(provider)} one!"
  end

  redirect '/settings/account'
end