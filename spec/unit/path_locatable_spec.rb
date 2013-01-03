describe DataMapper::Is::Locatable do
  include Sinatra::Locator

  before do mockup_user end
  it "should generate a user action paths" do
    User.url_for.should == 'users'
    Sinatra::Locator::url_for(@user).should == "/users/#{@user.id}"
    Sinatra::Locator::url_for(@user, :edit).should == "/users/#{@user.id}/edit"
    Sinatra::Locator::url_for(@user, :settings, :preferences).should == "/users/#{@user.id}/settings/preferences"
  end

  it "should generate category paths" do
    @c = @user.categories.create({ name: 'Food' })
    Sinatra::Locator.url_for(@c).should == "/users/#{@user.id}/categories/#{@c.id}"
  end

  it "should generate notice paths" do
    l = Sinatra::Locator
    n = @user.notices.first

    l.url_for(n).should match("/users/#{@user.id}/notices/#{n.salt}")
    l.url_for(n, :accept).should == "/users/#{@user.id}/notices/#{n.salt}/accept"
  end

  it "should generate account paths" do
    l = Sinatra::Locator
    l.url_for(@account).should == "/users/#{@user.id}/accounts/#{@account.id}"
  end

  it "should generate account transaction paths" do
    l = Sinatra::Locator
    tx = @a.deposits.create({ amount: 5 })
    l.url_for(tx).should == "/accounts/#{@account.id}/deposits/#{tx.id}"

    tx = @a.withdrawals.create({ amount: 5 })
    l.url_for(tx).should == "/accounts/#{@account.id}/withdrawals/#{tx.id}"

    tx = @a.recurrings.create({ amount: 5 })
    l.url_for(tx).should == "/accounts/#{@account.id}/recurrings/#{tx.id}"
  end

end