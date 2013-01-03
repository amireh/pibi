feature "User account settings" do
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

  def fill_form(q = {})
    sign_in

    click_link 'Manage'
    click_link 'Account'

    current_path.should == '/settings/account'

    within("form") do

      q.each_pair do |k,v|
        fill_in k.to_s, with: v
      end

      click_button 'Update Account'
    end

    current_path.should == '/settings/account'
  end

  scenario "Updating account name" do
    fill_form({ name: 'Botatis' })

    should_only_flash(:notice, 'account info updated')

    @user.refresh.name.should == 'Botatis'
  end

  scenario "Updating account with an empty name" do
    fill_form({ name: '' })

    should_only_flash(:error, 'need your name')

    # should not be changed
    @user.refresh.name.should == @mockup_user_params[:name]
  end

  scenario "Updating account with too long a name" do
    name = ''
    50.times do name += 'my_name_is' end
    fill_form({ name: name})

    should_only_flash(:error, 'need your name')

    # should not be changed
    @user.refresh.name.should == @mockup_user_params[:name]
  end

  scenario "Updating account email" do
    fill_form({ email: 'more@mysterious.com' })
    should_only_flash(:notice, 'account info updated')
    @user.refresh.email.should == 'more@mysterious.com'
    within("form") do
      page.should have_content('Verification pending.')
    end
  end

  scenario "Updating account with an invalid email" do
    fill_form({ email: 'laksdjf lkjadsflk@zxcv'})
    should_only_flash(:error, 'look like an email')
    @user.refresh.email.should == @mockup_user_params[:email]
  end

  scenario "Updating gravatar email" do
    fill_form({ :gravatar_email => 'more@mysterious.com' })
    should_only_flash(:notice, 'account info updated')
    @user.refresh.gravatar_email.should == 'more@mysterious.com'
  end
end # feature: User account settings
