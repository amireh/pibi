require 'models/transaction'

class Recurring < Transaction
  belongs_to :account, required: true

  property :flow_type,  Enum[ :positive, :negative ],      default: :positive
  property :frequency,  Enum[ :daily, :monthly, :yearly ], default: :monthly
  property :recurs_on,  DateTime, default: lambda { |*_| DateTime.now }
  property :last_commit, DateTime, allow_nil: true
  property :active,     Boolean, default: true

  def +(y)
    y
  end

  def applicable?(now = nil)
    now ||= DateTime.now

    case frequency
    when :daily
      # recurs_on is ignored in this frequency
      return !last_commit ||              # never committed before
        last_commit.year  < now.year  || # committed last year
        last_commit.month < now.month || # or last month
        last_commit.day   < now.day      # or yesterday, maybe
    when :monthly
      # is it the day of the month the tx should be committed on?
      if recurs_on.day == now.day
        # committed already for this month?
        return !last_commit ||
          last_commit.year  < now.year ||
          last_commit.month < now.month
      end
    when :yearly
      # is it the day and month of the year the tx should be committed on?
      if recurs_on.day == now.day && recurs_on.month == now.month
        # committed already for this year?
        return !last_commit || last_commit.year < now.year
      end
    end

    false
  end

  def commit(now = nil)
    return false unless self.active
    return false unless applicable?

    now ||= DateTime.now

    c = nil

    # get the transaction collection we'll be generating from/into
    if self.flow_type == :positive
      c = self.account.deposits
    else
      c = self.account.withdrawals
    end

    t = c.create({
      amount: self.amount,
      currency: self.currency,
      note: self.note,
      account: self.account
    })

    unless t.valid? && t.persisted?
      return false
    end

    # stamp the commit
    self.update({ last_commit: now })
  end

end