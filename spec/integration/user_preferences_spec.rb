feature "User pereferences" do
  background do
    mockup_user
  end

  def sign_in
    visit "/sessions/destroy"
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
    click_link 'Preferences'

    current_path.should == '/settings/preferences'
  end

  def fill_form(&cb)
    navigate_to_section

    within("form") do
      cb.call()
      click_button 'Update Preferences'
    end

    current_path.should == '/settings/preferences'
  end

  scenario "Changing default currency" do
    fill_form {
      select('GBP', from: 'currency')
    }

    should_only_flash(:notice, 'default currency now is GBP')

    @a.refresh.currency.should == 'GBP'
  end

  scenario "Adding a payment method" do
    old_pm_count = @user.payment_methods.count

    fill_form {
      fill_in 'payment_method[name]', with: 'My new PM'
    }

    should_only_flash(:notice, 'payment method My new PM registered')
    @user.refresh.payment_methods.count.should == old_pm_count + 1
  end

  scenario "Changing the default payment" do
    @user.payment_method.name.should_not == 'Credit Card'

    fill_form {
      choose('Credit Card')
    }

    @user.refresh.payment_method.name.should == 'Credit Card'

    should_only_flash(:notice, 'default payment method now is Credit Card')
  end

  scenario "Deleting the default payment", :js => true do
    pm = @user.payment_method
    pm_name = pm.name

    navigate_to_section

    link = page.find("[href*='#{pm.id.to_s}/destroy']")
    link.click
    within("#confirm") do
      click_button('Yes')
    end

    # the following is needed in order to force capybara-webkit to
    # redirect to the PM destruction page (which is done via JS)
    # see this: https://github.com/thoughtbot/capybara-webkit/issues/207
    #
    page.current_url

    # save_and_open_page
    @user.refresh.payment_method.name.should_not == pm_name

    # page.find('.flashes.notice').should have_content(/payment.*method.*removed/)
    should_only_flash(:notice, 'payment method removed')
    should_only_flash(:notice, "#{@user.refresh.payment_method.name} now your default method")
  end

  scenario "Deleting all payment methods", :js => true do
    3.times do
      navigate_to_section

      link = page.find("[href*='#{@user.payment_method.id.to_s}/destroy']")
      link.click
      within("#confirm") do
        click_button('Yes')
      end

      page.current_url
      should_only_flash(:notice, 'payment method removed')
    end

    @user.refresh.payment_methods.count.should == 1
  end

end # feature: User account settings
