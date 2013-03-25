require 'models/transaction_container'

class Account
  include DataMapper::Resource
  include TransactionContainer

  property :id,           Serial
  property :label,        String, length: 48, default: "Personal"

  # The account balance is the sum of all of its transaction actual amounts
  # converted to the account currency
  property :balance,      Decimal, scale: 2, default: 0

  # The account currency does not affect its transactions' currencies,
  # it is only used to figure out the exchange rate whenever the balance
  # is updated
  property :currency,     String, default: "USD"

  property :created_at,   DateTime, default: lambda { |*_| DateTime.now }

  belongs_to :user, required: true
  has n, :transactions, :constraint => :destroy
  has n, :deposits,     :constraint => :destroy
  has n, :withdrawals, :constraint => :destroy
  has n, :recurrings,   :constraint => :destroy

  validates_with_method :currency, :method => :check_currency

  # is :locatable

  # --------- -------
  # DISABLED: LOCKING
  # --
  # after :valid? do
  #   if self.user.locked?
  #     self.errors.add :user, "This action is not available to this account because it is locked."
  #     return false
  #   end
  #   true
  # end
  # is :lockable, :on => [ :balance ]
  # -----------------

  def check_currency
    unless Currency.valid?(self.currency)
      return [ false, "Currency must be one of #{Currencies.join(', ')}" ]
    end

    true
  end


end
