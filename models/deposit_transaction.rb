require 'models/transaction'

class Deposit < Transaction

  def add_to_account
    converted_amount = to_account_currency
    account.balance += converted_amount
    account.save
  end

  def deduct
    deductible_amount = to_account_currency
    account.balance -= deductible_amount
    account.save
  end

end