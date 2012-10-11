require 'models/transaction'

class Withdrawal < Transaction

  def add_to_account
    converted_amount = to_account_currency
    self.account.update({ balance: self.account.balance - converted_amount })
  end
  
  def deduct
    deductible_amount = to_account_currency
    self.account.update({ balance: self.account.balance + deductible_amount })
  end

end