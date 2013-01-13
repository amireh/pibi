route_namespace '/reports' do
  before do
    current_page("reports")
  end

  get '/yearly', auth: :user do
    @segments = {}

    for i in 0..(Time.now.year - current_account.transactions.last.occured_on.year)
      year = Time.new(Time.now.year - i, 1, 1)
      transies = current_account.yearly_transactions(year)
      @segments[year.year] = {
        balance: current_account.balance_for(transies),
        nr_transies: transies.count
      }
    end

    erb :"/reports/yearly"
  end

  get '/:year', auth: :user do |year|
    pass if year.to_i == 0

    @year  = year.to_i if year.is_a? String
    month = Time.now.month
    day   = Time.now.day

    # make sure the given date is sane
    begin
      @date = Time.new(year, month == 0 ? 1 : month, day == 0 ? 1 : day)
    rescue ArgumentError => e
      halt 400, "Invalid transaction period YYYY/MM/DD: '#{year}/#{month}/#{day}'"
    end

    @transies     = current_account.yearly_transactions(Time.new(year, 1, 1))
    @deposits     = current_account.yearly_deposits(Time.new(year, 1, 1))
    @withdrawals  = current_account.yearly_withdrawals(Time.new(year, 1, 1))

    @balance      = current_account.balance_for(@transies).to_f.round(2)
    @spendings    = current_account.balance_for(@withdrawals).to_f.round(2)
    @earnings     = current_account.balance_for(@deposits).to_f.round(2)

    @savings      = @earnings - @spendings.abs.to_f.round(2)
    @savings      = 0 if @savings < 0
    @segments     = {}

    @drilled = {
      savings:   Array.new(12,0.0),
      spendings: Array.new(12,0.0)
    }

    for i in 1..12 do
      @segments[i] = { balance: 0.0, nr_transies: 0 }

      # calculate the month's savings
      d = Time.new(@year, i, 1)
      earnings = current_account.monthly_earnings(d)
      spendings = current_account.monthly_spendings(d)

      # saved anything?
      savings = earnings - spendings.abs
      if savings > 0
        @drilled[:savings][i-1] = savings.to_f.round(0)
      end

      @drilled[:spendings][i-1] = spendings.to_f.round(0).abs
    end

    @transies.each { |tx|
      s = @segments[tx.occured_on.month.to_i]
      s[:balance] = tx + s[:balance]
      s[:nr_transies] += 1
    }

    @stats = {
      pm: [],
      categories: {
        top_spending: [],
        top_earning: []
      }
    }

    # Payment Method stats
    if @user.payment_methods.any? && @transies.count > 0
      @user.payment_methods.each do |pm|
        @stats[:pm] << {
          pm: pm,
          ratio: pm.transactions.count.to_f / @transies.count * 100.0,
          count: pm.transactions.count
        }
      end
    end

    # Category stats
    if @user.categories.any? && @transies.count > 0
      @stats[:categories][:top_spending] = @user.top_spending_categories
      @stats[:categories][:top_earning]  = @user.top_earning_categories
    end

    erb :"/reports/drilldowns/yearly"
  end
end


get '/reports*' do
  current_page("reports")
  erb :"static/coming_soon"
end