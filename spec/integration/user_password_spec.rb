feature "User password update" do
  background do
    mockup_user
  end

  def sign_in
    visit "/sessions/new"

    within("form") do
      fill_in 'email', :with => @user.email
      fill_in 'password', :with => @some_salt
    end

    click_button 'Login'

    current_path.should == '/'
    page.should have_selector('body.primary.transactions')
  end

  def navigate_to_section
    sign_in

    click_link 'Manage'
    click_link 'Account'
    click_link 'Password'

    current_path.should == '/settings/password'
  end

  def fill_form(q = {})
    navigate_to_section

    q = {
      :current      => @some_salt,
      :new          => 'foobar123',
      :confirmation => 'foobar123'
    }.merge(q)

    within("form") do
      fill_in 'password[current]',      with: q[:current]
      fill_in 'password[new]',          with: q[:new]
      fill_in 'password[confirmation]', with: q[:confirmation]

      click_button 'Update Password'
    end

    current_path.should == '/settings/password'
  end

  scenario "Blank new password" do
    fill_form({ :new => '', :confirmation => '' }) do
      should_only_flash(:error, 'must provide password')
    end
  end

  scenario "Mis-matched passwords" do
    fill_form({ :new => 'barfoo123' }) do
      should_only_flash(:error, 'must match')
    end
  end

  scenario "Password too short" do
    fill_form({ :new => 'bar', :confirmation => 'bar' }) do |page|
      should_only_flash(:error, 'be at least characters long')
    end
  end

  scenario "Incorrect current password" do
    fill_form({ :current => 'bar' }) do |page|
      should_only_flash(:error, "current password isn't correct")
    end
  end

  scenario "Correct parameters" do
    fill_form({ }) do |page|
      should_only_flash(:notice, 'password changed')
    end
  end

end # feature: User password
