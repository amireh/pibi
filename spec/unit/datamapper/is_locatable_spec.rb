class LocatorDelegate; include Sinatra::Locator::Helpers; end

describe DataMapper::Is::Locatable do
  def url_for(*args)
    LocatorDelegate.new.url_for(args)
  end

  before do mockup_user end

  it "should generate user resource paths" do
    url_for(@user).should == "/users/#{@user.id}"
    url_for(@user, :edit).should == "/users/#{@user.id}/edit"
    url_for(@user, :settings, :preferences).should == "/users/#{@user.id}/settings/preferences"
  end

  it "should generate user collection paths" do
    url_for(User).should          == '/users'
    url_for(User, :index).should  == '/users'
    url_for(User, :new).should    == '/users/new'
  end

  it "should generate category paths" do
    @c = @user.categories.create({ name: 'Food' })

    url_for(@c).should == "/users/#{@user.id}/categories/#{@c.id}"
    url_for(@c, :edit).should == "/users/#{@user.id}/categories/#{@c.id}/edit"
    url_for(@c, :destroy).should == "/users/#{@user.id}/categories/#{@c.id}/destroy"
  end

  it "should generate category collection paths" do
    url_for(@user.categories).should == "/users/#{@user.id}/categories"
    url_for(@user.categories, :index).should == "/users/#{@user.id}/categories"
    url_for(@user.categories, :new).should == "/users/#{@user.id}/categories/new"
  end

  it "should generate notice paths" do
    n = @user.notices.first

    url_for(n).should match("/users/#{@user.id}/notices/#{n.salt}")
    url_for(n, :accept).should == "/users/#{@user.id}/notices/#{n.salt}/accept"
  end

  it "should generate notice collection paths" do
    n = @user.notices.first

    url_for(@user.notices, :index).should match("/users/#{@user.id}/notices")
    url_for(@user.notices, :new).should == "/users/#{@user.id}/notices/new"
  end

  it "should generate account paths" do
    url_for(@account).should == "/users/#{@user.id}/accounts/#{@account.id}"
    url_for(@user.accounts.first).should == "/users/#{@user.id}/accounts/#{@account.id}"
  end

  it "should generate account transaction paths" do
    tx = @a.deposits.create({ amount: 5 })
    url_for(tx).should == "/accounts/#{@account.id}/deposits/#{tx.id}"

    tx = @a.withdrawals.create({ amount: 5 })
    url_for(tx).should == "/accounts/#{@account.id}/withdrawals/#{tx.id}"

    tx = @a.recurrings.create({ amount: 5 })
    url_for(tx).should == "/accounts/#{@account.id}/recurrings/#{tx.id}"
  end

  it "should obey the shallow option" do
    tx = @a.deposits.create({ amount: 5 })
    url_for(tx, shallow: true).should == "/deposits/#{tx.id}"

    url_for(@user.categories, :edit, shallow: true).should == '/categories/edit'
  end

end