feature "Signing in" do
  background do
    mockup_user
  end

  scenario "Signing in with correct credentials" do
    visit "/sessions/new"

    within("form") do
      fill_in 'email', :with => @user.email
      fill_in 'password', :with => @some_salt
    end

    click_button 'Login'

    current_path.should == '/'
    page.should have_selector('body.primary.transactions')
  end

  scenario "Signing in with incorrect credentials" do
    visit "/sessions/new"

    within("form") do
      fill_in 'email', :with => @user.email
      fill_in 'password', :with => 'foobar'
    end

    click_button 'Login'

    current_path.should == '/sessions/new'
    page.should have_selector('.flashes.error')
  end
end