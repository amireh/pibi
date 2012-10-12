describe Category do
  
  before do
    User.destroy

    @user = User.create({
      name: "Ahmad Amireh",
      email: "ahmad@amireh.net",
      provider: "pibi",
      uid: "1234",
      password: User.encrypt('hello world')
    })

    @account = @user.accounts.create()
  end

  it "should create a category" do
    @user.categories.count.should == 0
    c = @user.categories.create({ name: "Utility" })
    c.errors.size.should == 0
    c.saved?.should be_true
    @user.categories.count.should == 1
  end
  
  it "should attach a category to a tx" do
    @user.categories.count.should == 0
    c = @user.categories.create({ name: "Utility" })
    c.errors.size.should == 0
    c.saved?.should be_true
    @user.categories.count.should == 1

    t = @account.deposits.create({ amount: 5, account: @account })
    t.errors.size.should == 0
    t.saved?.should be_true

    t.categories << c
    t.save

    c = c.refresh
    c.transactions.count.should == 1
  end

  it "should detach a tx from a category" do
    @user.categories.count.should == 0
    c = @user.categories.create({ name: "Utility" })
    c.errors.size.should == 0
    c.saved?.should be_true
    @user.categories.count.should == 1

    t = @account.deposits.create({ amount: 5, account: @account })
    t.errors.size.should == 0
    t.saved?.should be_true

    t.categories << c
    t.save

    c = c.refresh
    c.transactions.count.should == 1
    CategoryTransaction.all.count.should == 1

    c.destroy.should be_true

    CategoryTransaction.all.count.should == 0

    t = t.refresh
    t.should be_true
    t.categories.count.should == 0

    Category.all.count.should == 0
    Transaction.all.count.should == 1
  end

  it "should attach many transies to a category" do
    # create a category
    @user.categories.count.should == 0
    c = @user.categories.create({ name: "Utility" })
    c.errors.size.should == 0
    c.saved?.should be_true
    @user.categories.count.should == 1

    # create a couple of txes
    t = @account.deposits.create({ amount: 5, account: @account })
    t.errors.size.should == 0
    t.saved?.should be_true
    t.categories << c
    t.save

    t = @account.withdrawals.create({ amount: 5, account: @account })
    t.errors.size.should == 0
    t.saved?.should be_true
    t.categories << c
    t.save

    c.transactions.all.count.should == 2
    CategoryTransaction.all.count.should == 2
    c.destroy
    CategoryTransaction.all.count.should == 0
    Transaction.all.count.should == 2
    Category.all.count.should == 0
  end

end
