describe "Recurring Transactions" do
  
  before do
    User.destroy
    # Transaction.destroy
    # Account.destroy

    @user = User.create({
      name: "Ahmad Amireh",
      email: "ahmad@amireh.net",
      provider: "pibi",
      uid: "1234",
      password: User.encrypt('hello world')
    })

    @account = @user.accounts.create()
  end

  it "should create a recurring transaction" do
    @account.recurrings.all.count.should == 0
    @account.recurrings.create({ amount: 5, account: @account })
    @account.recurrings.all.count.should == 1
  end

  it "should commit a recurring transaction" do
    @account.recurrings.all.count.should == 0
    rt = @account.recurrings.create({ amount: 5, account: @account })
    @account.recurrings.all.count.should == 1

    @account.balance.to_f.should == 0
    
    rt.commit.should be_true

    @account = @account.refresh
    @account.balance.to_f.should == 5.0
  end

  it "should respect the type of a recurring transaction" do
    @account.recurrings.all.count.should == 0
    rt = @account.recurrings.create({ amount: 5, flow_type: :negative, account: @account })
    @account.recurrings.all.count.should == 1

    @account.balance.to_f.should == 0
    
    rt.commit.should be_true

    @account = @account.refresh
    @account.balance.to_f.should == -5.0
  end

  it "should not commit the transaction more than necessary" do
    @account.recurrings.all.count.should == 0
    rt = @account.recurrings.create({ amount: 5, flow_type: :negative, account: @account })
    @account.recurrings.all.count.should == 1

    @account.balance.to_f.should == 0
    
    rt.applicable?.should be_true
    rt.commit.should be_true
    rt.applicable?.should be_false

    @account = @account.refresh
    @account.balance.to_f.should == -5.0
    
    rt.commit.should be_false
  end

  it "should commit a daily RT only once a day" do
    rt = @account.recurrings.create({ 
      amount: 10,
      flow_type: :negative,
      frequency: :daily,
      account: @account
    })
    
    rt.applicable?.should be_true
    rt.commit.should be_true
    rt.applicable?.should be_false

    @account = @account.refresh
    @account.balance.to_f.should == -10.0
    
    t = DateTime.now
    rt.applicable?(DateTime.new(t.year,t.month,t.day+1)).should be_true
    rt.applicable?(DateTime.new(t.year,t.month+1,t.day)).should be_true
    rt.applicable?(DateTime.new(t.year+1,t.month,t.day)).should be_true
    rt.applicable?(DateTime.new(t.year,t.month,t.day-1)).should be_false
    rt.applicable?(DateTime.new(t.year,t.month-1,t.day)).should be_false
    rt.applicable?(DateTime.new(t.year-1,t.month,t.day)).should be_false
  end

  it "should commit a monthly RT only once a month" do
    rt = @account.recurrings.create({ 
      amount: 10,
      flow_type: :negative,
      frequency: :monthly,
      account: @account
    })
    
    rt.applicable?.should be_true
    rt.commit.should be_true
    rt.applicable?.should be_false

    @account = @account.refresh
    @account.balance.to_f.should == -10.0
    
    t = DateTime.now
    rt.applicable?(DateTime.new(t.year,t.month,t.day+1)).should be_false
    rt.applicable?(DateTime.new(t.year,t.month+1,t.day)).should be_true
    rt.applicable?(DateTime.new(t.year+1,t.month,t.day)).should be_true
    rt.applicable?(DateTime.new(t.year,t.month,t.day-1)).should be_false
    rt.applicable?(DateTime.new(t.year,t.month-1,t.day)).should be_false
    rt.applicable?(DateTime.new(t.year-1,t.month,t.day)).should be_false
  end

  it "should commit a yearly RT only once a year" do
    rt = @account.recurrings.create({ 
      amount: 10,
      flow_type: :negative,
      frequency: :yearly,
      account: @account
    })
    
    rt.applicable?.should be_true
    rt.commit.should be_true
    rt.applicable?.should be_false

    @account = @account.refresh
    @account.balance.to_f.should == -10.0
    
    t = DateTime.now
    rt.applicable?(DateTime.new(t.year,t.month,t.day+1)).should be_false
    rt.applicable?(DateTime.new(t.year,t.month+1,t.day)).should be_false
    rt.applicable?(DateTime.new(t.year+1,t.month,t.day)).should be_true
    rt.applicable?(DateTime.new(t.year,t.month,t.day-1)).should be_false
    rt.applicable?(DateTime.new(t.year,t.month-1,t.day)).should be_false
    rt.applicable?(DateTime.new(t.year-1,t.month,t.day)).should be_false
  end

end