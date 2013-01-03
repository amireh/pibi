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

  [ :daily, :monthly, :yearly ].each { |period|
    define_method(:"#{period}_expenses") {
      expenses = 0.0
      recurrings.all({frequency: period }).each { |t| expenses = t + expenses }
      expenses
    }
  }

  validates_with_method :currency, :method => :check_currency

  is :locatable

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

  def latest_transactions(q = {}, t = nil)
    transactions_in(nil, q)
    # transactions.all({ :occured_on.gte => Timetastic.this.month, :occured_on.lt => Timetastic.next.month }.merge(q))
  end

  def yearly_transactions(date = Timetastic.this.year, q = {})
    c = []
    Timetastic.fixate(date) {
      c = transactions_in({ :begin => Timetastic.this.year, :end => Timetastic.next.year }, q)
    }
    c
  end

  def monthly_transactions(date = Timetastic.this.month, q = {})
    c = []
    Timetastic.fixate(date) {
      c = transactions_in({ :begin => Timetastic.this.month, :end => Timetastic.next.month }, q)
    }
    c
  end

  def daily_transactions(date = Timetastic.this.day, q = {})
    c = []
    Timetastic.fixate(date) {
      c = transactions_in({ :begin => Timetastic.this.day, :end => Timetastic.next.day }, q)
    }
    c
  end

  def yearly_balance(date_or_collection, q = {})
    c = []
    if date_or_collection.is_a?(DataMapper::Collection)
      c = date_or_collection
    else
      c = yearly_transactions(date_or_collection, q)
    end

    balance_for c
  end

  def monthly_balance(date_or_collection, q = {})
    c = []
    if date_or_collection.is_a?(DataMapper::Collection)
      c = date_or_collection
    else
      c = monthly_transactions(date_or_collection, q)
    end

    balance_for c
  end

  def transactions_in(range = {}, q = {})
    range ||= {
      :begin => Timetastic.this.month,
      :end => Timetastic.next.month
    }

    transactions.all({
      :occured_on.gte => range[:begin],
      :occured_on.lt => range[:end],
      :type.not => Recurring,
      :order => [ :occured_on.desc ]
    }.merge(q))
  end

  def balance_for(collection)
    balance = 0.0
    collection.each { |tx| balance = tx + balance }
    balance
  end

end