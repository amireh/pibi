feature "Notifications: pending & accepted" do
  def sign_in
    visit "/sessions/new"

    within("form") do
      fill_in 'email', :with => @user.email
      fill_in 'password', :with => @some_salt
    end

    click_button 'Login'

    # current_path.should == '/'
    page.should have_selector('body.primary.transactions')
  end

  background do
    mockup_user
    sign_in
  end

  scenario "Can't go anywhere! Auto-password lockdown" do
    @user.generate_temporary_password

    visit "/"
    current_path.should == '/settings/password'

    visit "/transactions/deposits/new"
    current_path.should == '/settings/password'

    page.find('#content').should have_keywords('temporary password has been generated')
  end

  scenario "Changing the auto-password, now I can go..." do
    @user.update({ auto_password: true })

    visit "/"
    current_path.should == '/settings/password'

    page.find('#content').should have_keywords('temporary password has been generated')

    within("form") do
      fill_in 'password[current]',      with: @user.notices.last.data
      fill_in 'password[new]',          with: @some_salt
      fill_in 'password[confirmation]', with: @some_salt

      click_button 'Update Password'
    end

    should_only_flash(:notice, 'password changed')

    @user.refresh.auto_password.should be_false

    visit '/'
    current_path.should == '/'
  end

  scenario "Running with an unverified email" do
    visit '/settings/notifications'

    page.find('#content section ol').should have_keywords('email not yet verified')

    visit '/settings/account'
    page.find('#content fieldset').should have_keywords('Verification pending')
  end

  scenario "Accepting the email verification notice link" do
    visit @user.notices.first({ type: 'email' }).acceptance_url

    should_only_flash(:notice, 'email has been verified')

    visit '/settings/notifications'
    page.find('#content section').should_not have_keywords('email not yet verified')
    page.find('#content section').should have_keywords('correctly closed all snowman')

    visit '/settings/account'
    page.find('#content fieldset').should have_keywords('Verified')

    page.should_not have_selector('span.notifications')
  end
end