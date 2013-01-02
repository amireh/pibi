describe Transaction do
  before do
    mockup_user
  end

  it "should reject a tx without an amount" do
    tx = @account.transactions.create({ amount: nil })
    tx.saved?.should be_false
    tx.all_errors.first.should match(/amount is missing/)
  end

  it "should convert to account currency" do
    tx = @account.transactions.create({ amount: 10, currency: "JOD" })
    tx.__to_account_currency.should == Currency["USD"].from("JOD", tx.amount)
  end
end