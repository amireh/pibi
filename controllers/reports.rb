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

    year  = year.to_i if year.is_a? String
    month = Time.now.month
    day   = Time.now.day

    # make sure the given date is sane
    begin
      @date = Time.new(year, month == 0 ? 1 : month, day == 0 ? 1 : day)
    rescue ArgumentError => e
      halt 400, "Invalid transaction period YYYY/MM/DD: '#{year}/#{month}/#{day}'"
    end

    @drilldown = "yearly"
    @transies = current_account.yearly_transactions(Time.new(year, 1, 1))
    @segments = {}
    for i in 1..12 do @segments[i] = { balance: 0.0, nr_transies: 0 } end
    @transies.each { |tx|
      s = @segments[tx.occured_on.month.to_i]
      s[:balance] = tx + s[:balance]
      s[:nr_transies] += 1
    }

    erb :"/reports/drilldowns/yearly"
  end
end


get '/reports*' do
  current_page("reports")
  erb :"static/coming_soon"
end