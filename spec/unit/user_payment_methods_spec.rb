describe PaymentMethod do

  before do
    User.destroy

    @some_salt = Pibi.salt
    @u = User.create({
      name: 'Mysterious Mocker',
      email: 'very@mysterious.com',
      provider: 'pibi',
      password: @some_salt,
      password_confirmation: @some_salt
    })
  end

  it "should create a pm" do
    pm = @u.payment_methods.create({ name: 'Galaxy Coins' })
    pm.valid?.should be_true
    pm.saved?.should be_true
  end

  it "should not create a pm with a duplicate name" do
    pm = @u.payment_methods.create({ name: 'Cash' })
    pm.valid?.should be_false
    pm.saved?.should be_false
    pm.all_errors.first.should match(/name.*already.*exists/)
  end

  it "should not create a pm with an empty name" do
    pm = @u.payment_methods.create({ name: '' })
    pm.valid?.should be_false
    pm.saved?.should be_false
    pm.all_errors.first.should match(/requires a name/)
  end

  it "should not allow for more than one default pm" do
    pm = @u.payment_methods.last
    pm.default.should be_false
    pm.update({ default: true }).should be_false
    pm.valid?.should be_false
    pm.all_errors.first.should match(/already have a default/)
  end

  it "should change the default pm" do
    dpm = @u.payment_method
    dpm.update({ default: false }).should be_true
    pm = @u.payment_methods.last
    pm.default.should be_false
    pm.update({ default: true }).should be_true
  end

  it "should change the default pm using the internal method" do
    @u.payment_method = @u.payment_methods.last
    @u.payment_method.name.should == @u.payment_methods.last.name
  end

end