describe Transaction do
  before do
    User.destroy

    @user = User.create({
      name: "Ahmad Amireh",
      email: "ahmad@amireh.net",
      provider: "pibi",
      uid: "1234",
      password: User.encrypt('hello world')
    })

    @a = @user.accounts.first
  end

  it "should adjust account balance after update" do
    puts "----"
    @a.balance.should == 0

    tx = @a.deposits.create({ amount: 5 })
    @a.balance.to_f.should == 5

    tx.update({ amount: 7 })
    @a.balance.to_f.should == 7

    tx.update({ amount: 10 })
    @a.balance.to_f.should == 10

    @a.deposits.destroy
    @a.balance.to_f.should == 0
  end
end