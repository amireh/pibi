class Transaction
  include DataMapper::Resource

  property :id,           Serial

  # The raw amount of the transaction.
  property :amount,       Decimal, scale: 2, required: true

  # The transaction currency is the currency used when the transaction
  # was made, and if it differs from the account currency, the proper
  # exchange rate conversion will be made in the account balance and NOT
  # the transaction itself.
  property :currency,     String, length: 3, default: lambda { |r,*_| r.account.currency }

  property :note,         Text, default: ""

  # Transactions can be either deposits, withdrawals, or transfers
  property :type, Discriminator

  property :occured_on,   DateTime, default: lambda { |*_| DateTime.now }
  property :created_at,   DateTime, default: lambda { |*_| DateTime.now }

  belongs_to :account, required: true

  has n, :categories, :through => Resource, :constraint => :skip

  before :destroy do
    CategoryTransaction.all({ transaction_id: self.id }).destroy!

    true
  end

  [ :update, :destroy ].each do |advice|
    before advice do
      # puts "Deducting my current amount #{self.amount.to_f}(#{self.currency}) from the account balance (#{self.account.balance.to_f}"
      deduct
    end
  end

  [ :update, :create ].each do |advice|

    before advice do |ctx|
      unless Currency.valid?(ctx.currency)
        ctx.errors.add :currency, "Currency must be one of #{Currencies.join(', ')}"
        throw :halt
      end
    end

    after advice do
      add_to_account
    end
  end

  def deduct
  end

  def add_to_account
  end

  def serialize(with_note = false)
    s = {
      id: id,
      amount: amount,
      currency: currency,
      account_id: account_id
    }

    s.merge!({ note: note }) if with_note
    s
  end

  def to_json(*args)
    serialize(args).to_json
  end

  protected

  def to_account_currency
    ac = Currency[self.account.currency]
    mc = Currency[self.currency]

    ac.from(mc, self.amount)
  end  
end