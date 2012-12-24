describe User do

  before do
    User.destroy
  end

  it "should create a user with a default account" do
    @user = User.create({
      name: "Ahmad Amireh",
      email: "ahmad@amireh.net",
      provider: "pibi",
      uid: "1234",
      password: User.encrypt('hello world')
    })

    @user.should be_true
    @user.accounts.count.should == 1
    @user.saved?.should be_true

    @user.accounts.first.balance.to_f.should == 0.0
  end

end