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

  validates_with_method :currency, :method => :check_currency

  [ 'withdrawal', 'deposit', 'recurring' ].each { |t|
    define_method("#{t}?") { self.type.to_s == t.capitalize }
    alias_method :"is_#{t}?", :"#{t}?"
  }

  def url
    "/transactions/#{self.type.to_s.downcase}s/#{self.id}"
  end

  def check_currency
    unless Currency.valid?(self.currency)
      return [ false, "Currency must be one of #{Currencies.join(', ')}" ]
    end

    true
  end

  def +(y)
    y
  end

  [ :update, :destroy ].each do |advice|
    before advice do |ctx|
      puts "[ before #{advice} ] #{self.id} #{self.type} Deducting my current amount (#{to_account_currency.to_f}) from the account balance (#{self.account.balance.to_f} #{self.account.currency})"
      deduct# if persisted?
      puts "[ before #{advice} ] \t#{self.id} #{self.type} account balance = (#{self.account.balance.to_f} #{self.account.currency})"
      true
    end
  end

  [ :update, :create ].each do |advice|
    after advice do
      puts "[ after #{advice} ] #{self.id} #{self.type} Adding my current amount (#{to_account_currency.to_f}) to the account balance (#{self.account.balance.to_f} #{self.account.currency})"

      # if account.dirty? || dirty?
      #   raise RuntimeError.new "Account is already dirty before adding: #{account.dirty_attributes}, #{dirty_attributes}"
      # end

      add_to_account# if persisted?

      puts "[ after #{advice} ] \t#{self.id} #{self.type} account balance = (#{self.account.balance.to_f} #{self.account.currency})"

      # if account.dirty? || dirty?
      #   raise RuntimeError.new "Account is still dirty after adding: #{account.dirty_attributes}, #{dirty_attributes}"
      # end

      true
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

    # ac.from(mc, self.amount)
    amt = (Transaction.get(self.id) || self).amount
    ac.from(mc, amt)
  end
end