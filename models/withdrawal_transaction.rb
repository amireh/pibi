require 'models/transaction'

class Withdrawal < Transaction
  belongs_to :account, required: true

  def add_to_account
    converted_amount = to_account_currency
    new_balance = account.balance - converted_amount
    account.balance = new_balance
    account.save!
    # account = self.account.refresh
    # unless account.update({ balance: new_balance })
      # raise RuntimeError.new "Unable to update the account: #{account.dirty?} => #{account.collect_errors}"
    # end
  end

  def deduct
    deductible_amount = to_account_currency
    new_balance = account.balance + deductible_amount
    account.balance = new_balance
    account.save!
    # account = self.account.refresh
    # unless account.update({ balance: new_balance })
      # raise RuntimeError.new "Unable to update the account: #{account.dirty?} => #{account.collect_errors}"
    # end
  end

  def +(y)
    to_account_currency * -1 + y
  end

end