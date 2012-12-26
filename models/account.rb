class Account
  include DataMapper::Resource

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

  belongs_to :user
  has n, :transactions, :constraint => :destroy
  has n, :deposits,     :constraint => :destroy
  has n, :withdrawals, :constraint => :destroy
  has n, :recurrings,   :constraint => :destroy

  # Accepted options:
  # => :with_transactions: the account transactions will be dumped
  # => :with_transaction_notes: the account transaction notes will be dumped
  def serialize(o = {})
    s = {
      id: id,
      label: label,
      balance: balance,
      currency: currency
    }

    if o[:with_transactions] then
      s[:transactions] = {}
      transactions.each { |t| s[:transactions] << t.serialize(o[:with_transaction_notes]) }
    end

    s
  end

  def to_json(*args)
    serialize(args).to_json
  end

end