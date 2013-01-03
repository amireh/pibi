describe User do

  before do
    User.destroy
  end

  def mock_params()
    @some_salt = Pibi.salt
    {
      name: 'Mysterious Mocker',
      email: 'very@mysterious.com',
      provider: 'pibi',
      password: @some_salt,
      password_confirmation: @some_salt
    }
  end

  def mock_password(salt)
    { password: salt, password_confirmation: salt }
  end

  it "should create a user" do
    u = User.create(mock_params)

    u.valid?.should be_true
    u.saved?.should be_true
  end

  it "should create a user with a default account and payment method" do
    u = User.create(mock_params)

    u.valid?.should be_true
    u.saved?.should be_true
    u.accounts.count.should == 1

    # Cash, Cheque, and Credit Card
    u.payment_methods.count.should == 3

    # default payment method
    u.payment_method.should be_true
  end

  it "should not create a user because of password length" do
    u = User.new(mock_params.merge(mock_password('foo')))
    u.valid?.should be_false
    u.all_errors.first.should match(/must be at least/)

    u.save.should be_false

    u = User.create(mock_params.merge(mock_password('foo')))
    u.saved?.should be_false
  end

  it "should not create a user because of password mismatch" do
    u = User.new(mock_params.merge({ password: 'foobar123' }))
    u.valid?.should be_false
    u.all_errors.first.should match(/must match/)

    u.save.should be_false
  end

  it "should not create a user because of missing password" do
    u = User.new(mock_params.merge({ password: '', password_confirmation: '' }))
    u.valid?.should be_false
    u.all_errors.first.should match(/must provide/)

    u.save.should be_false
  end

  it "should not create a user because of missing email" do
    u = User.new(mock_params.merge({ email: '' }))
    u.valid?.should be_false
    u.all_errors.first.should match(/need your email/)

    u.save.should be_false
  end

  it "should not create a user because of invalid email" do
    u = User.new(mock_params.merge({ email: 'domdom@baz' }))
    u.valid?.should be_false
    u.all_errors.first.should match(/look like an email/)

    u.save.should be_false
  end

  it "should not create a user because of unavailable email" do
    u = User.create(mock_params)
    u.valid?.should be_true
    u.saved?.should be_true

    u = User.new(mock_params)
    u.valid?.should be_false
    u.all_errors.first.should match(/already.*registered/)

    u.save.should be_false
  end

  it "should not create a user because of missing name" do
    u = User.new(mock_params.merge({name: ''}))
    u.valid?.should be_false
    u.all_errors.first.should match(/need your name/)

    u.save.should be_false
  end
end