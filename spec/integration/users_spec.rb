feature "Signing up for a new account" do
  background do
    mockup_user
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
      page.should have_selector('.flashes.error')
    end

    cb.call(page) if block_given?
  end

  scenario "Signing up with no name" do
    fill_form({ name: '' }) do |page|
      page.find('.flashes.error').should have_keywords('need your name')
    end
  end

  scenario "Signing up with no email" do
    fill_form({ email: '' }) do |page|
      page.find('.flashes.error').should have_keywords('need your email')
    end
  end

  scenario "Signing up with an invalid email" do
    fill_form({ email: 'this is no email' }) do |page|
      page.find('.flashes.error').should have_keywords('look like an email')
    end
  end

  scenario "Signing up with a taken email" do
    fill_form({ email: @user.email }) do |page|
      page.find('.flashes.error').should have_keywords('already registered')
    end
  end

  scenario "Signing up without a password" do
    fill_form({ password: '' }) do |page|
      page.find('.flashes.error').should have_keywords('must provide password')
    end
  end

  scenario "Signing up with mis-matched passwords" do
    fill_form({ password: 'barfoo123' }) do |page|
      page.find('.flashes.error').should have_keywords('must match')
    end
  end

  scenario "Signing up with a password too short" do
    fill_form({ password: 'bar', password_confirmation: 'bar' }) do |page|
      page.find('.flashes.error').should have_keywords('be at least characters long')
    end
  end

  scenario "Signing up with correct info" do
    fill_form do |page|
      current_path.should == '/'
      page.should have_selector('.flashes.notice')
    end
  end

end
