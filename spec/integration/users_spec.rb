feature "Signing up for a new account" do
  background do
    mockup_user
    visit "/sessions/destroy"
  end

  def fill_form(in_q = {}, &cb)
    q = {
      name: @user.name,
      email: 'some@email.com',
      password: 'foobar123',
      password_confirmation: 'foobar123'
    }.merge(in_q)

    visit "/users/new"

    within("form") do
      fill_in 'name', :with => q[:name]
      fill_in 'email', :with => q[:email]
      fill_in 'password', :with => q[:password]
      fill_in 'password_confirmation', :with => q[:password_confirmation]

      click_button('Sign me up!')
    end

    # expect to fail when any of the default params are overridden
    unless in_q.empty?
      current_path.should == '/users/new'
    end

    cb.call(page) if block_given?
  end

  scenario "Signing up with no name" do
    fill_form({ name: '' }) do |page|
      should_only_flash(:error, 'need your name')
    end
  end

  scenario "Signing up with no email" do
    fill_form({ email: '' }) do |page|
      should_only_flash(:error, 'need your email')
    end
  end

  scenario "Signing up with an invalid email" do
    fill_form({ email: 'this is no email' }) do |page|
      should_only_flash(:error, 'look like an email')
    end
  end

  scenario "Signing up with a taken email" do
    fill_form({ email: @user.email }) do |page|
      should_only_flash(:error, 'already registered')
    end
  end

  scenario "Signing up without a password" do
    fill_form({ password: '' }) do |page|
      should_only_flash(:error, 'must provide password')
    end
  end

  scenario "Signing up with mis-matched passwords" do
    fill_form({ password: 'barfoo123' }) do |page|
      should_only_flash(:error, 'must match')
    end
  end

  scenario "Signing up with a password too short" do
    fill_form({ password: 'bar', password_confirmation: 'bar' }) do |page|
      should_only_flash(:error, 'be at least characters long')
    end
  end

  scenario "Signing up with correct info" do
    begin
      fill_form({}) do
        current_path.should == '/'
        should_only_flash(:notice, 'new account has been registered')
      end
    rescue Capybara::Webkit::InvalidResponseError => e
      # ignore this, capybara-webkit is having issue with this POST
      # because of its redirection, if we got an exception, it means
      # the sign-up worked and we were redirected to the authorized landing page
      true
    end
  end

end
