ENV['RACK_ENV'] = 'test'

require 'app'
set :environment, :test

describe Transaction do
  
  before do
    User.destroy
    Transaction.destroy
    Account.destroy

    @user = User.create({
      name: "Ahmad Amireh",
      email: "ahmad@amireh.net",
      provider: "pibi",
      uid: "1234",
      password: User.encrypt('hello world')
    })

    @account = @user.accounts.create()
  end

  it "should create a deposit transaction" do
    @account.deposits.all.count.should == 0
    @account.deposits.create({ amount: 5, account: @account })
    @account.deposits.all.count.should == 1
  end

  it "should create a withdrawal transaction" do
    @account.withdrawals.all.count.should == 0
    @account.withdrawals.create({ amount: 5, account: @account })
    @account.withdrawals.all.count.should == 1
  end

  it "should increase the account balance" do
    @account.deposits.all.count.should == 0
    @account.balance.to_f.should == 0.0
    @account.deposits.create({ amount: 5, account: @account })
    @account.balance.to_f.should == 5.0
  end

  it "should decrease the account balance" do
    @account.withdrawals.all.count.should == 0
    @account.balance.to_f.should == 0.0
    @account.withdrawals.create({ amount: 5, account: @account })
    @account.balance.to_f.should == -5.0
  end

  it "should increase the account balance and respect the currency difference" do
    @account.deposits.all.count.should == 0
    @account.balance.to_f.should == 0.0
    @account.deposits.create({ amount: 7.0, currency: "JOD", account: @account })
    @account.balance.to_f.should == 10.0
  end

  it "should decrease the account balance and respect the currency difference" do
    @account.withdrawals.all.count.should == 0
    @account.balance.to_f.should == 0.0
    @account.withdrawals.create({ amount: 7.0, currency: "JOD", account: @account })
    @account.balance.to_f.should == -10.0
  end

  it "should deduct from the account balance and respect the currency difference" do
    @account.deposits.all.count.should == 0
    @account.balance.to_f.should == 0.0
    @account.deposits.create({ amount: 7.0, currency: "JOD", account: @account })
    @account.balance.to_f.should == 10.0
    @account.deposits.destroy
    @account.deposits.all.count.should == 0
    @account = Account.get(@account.id)
    @account.balance.to_f.should == 0.0
  end

  it "should put back into the account balance and respect the currency difference" do
    @account.withdrawals.all.count.should == 0
    @account.balance.to_f.should == 0.0
    @account.withdrawals.create({ amount: 7.0, currency: "JOD", account: @account })
    @account.balance.to_f.should == -10.0
    @account.withdrawals.destroy
    @account.withdrawals.all.count.should == 0
    @account = Account.get(@account.id)
    @account.balance.to_f.should == 0.0
  end

end