class Transaction
  include DataMapper::Resource

  property :id,           Serial

  # The raw amount of the transaction.
  property :amount,       Decimal, scale: 2, required: true,
    message: 'Transaction amount is missing.'

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
  belongs_to :payment_method, default: lambda { |tx,*_| tx.account.user.payment_method }

  has n, :categories, :through => Resource, :constraint => :skip

  before :destroy do
    CategoryTransaction.all({ transaction_id: self.id }).destroy
  end

  validates_with_method :currency, :method => :check_currency

  [ 'withdrawal', 'deposit', 'recurring' ].each { |t|
    define_method("#{t}?") { self.type.to_s == t.capitalize }
    alias_method :"is_#{t}?", :"#{t}?"
  }

  is :locatable, shallow: true

  # def url
  #   "/transactions/#{self.type.to_s.downcase}s/#{self.id}"
  # end

  def check_currency
    unless Currency.valid?(self.currency)
      return [ false, "Currency must be one of #{Currencies.join(', ')}" ]
    end

    true
  end

  def +(y)
    y
  end

  # --------- -------
  # DISABLED: LOCKING
  # --
  # [ :create, :save, :update, :destroy ].each do |advice|
  #   before advice do |ctx|
  #     if self.account.user.locked?
  #       # puts "Tx: halting #{advice} because my account is locked: #{account.collect_errors}"
  #       self.errors.add :account, account.collect_errors
  #       throw :halt
  #     end
  #   end
  # end
  # -----------------

  after :create do
    add_to_account(to_account_currency)
    self.account.save
  end

  # adjust the account balance if our amount or currency are being updated
  before :update do
    needs_adjustment = attribute_dirty?(:amount) || attribute_dirty?(:currency)

    if needs_adjustment

      # deduction:
      # the deductible amount should be what the amount and currency
      # where prior to the update *if* they were updated, technically
      # we have 4 permutations here

      dd_currency = case attribute_dirty?(:currency)
      when true;  original_attributes[Transaction.currency] # currency is dirty, get original
      when false; self[:currency]
      end

      dd_amount = case attribute_dirty?(:amount)
      when true;  original_attributes[Transaction.amount] # amount is dirty, get original
      when false; self[:amount]
      end

      deductible_amount = to_account_currency(dd_amount, dd_currency)
      deduct(deductible_amount)

      # addition:
      # nothing special to do here since the new amount and currency
      # are set already, see #to_account_currency
      added_amount = to_account_currency
      add_to_account(added_amount)

      # note the bang (!) version; we MUST bypass all hooks here
      # since otherwise there'd be a chicken-and-egg paradox!
      #
      # (account is dirty and can't be updated because the tx itself
      #  is dirty, which needs the account to be updated, and clean, to update)
      self.account.save!
    end
  end

  before :destroy do
    deduct(to_account_currency)
    self.account.save
  end

  def deduct(amt)
  end

  def add_to_account(amt)
  end

  # exposed only for unit tests, you really shouldn't need to use this
  def __to_account_currency # :nodoc:
    to_account_currency
  end

  protected

  def to_account_currency(amount = self[:amount], mine = self[:currency])
    Currency[self.account[:currency]].from(Currency[mine], amount)
  end
end