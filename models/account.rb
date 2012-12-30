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