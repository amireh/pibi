[ 'deposits', 'withdrawals', 'recurrings' ].each do |type|

  namespace "/transactions/#{type}" do
    condition do
      restrict_to(:user)
    end

    before do
      current_page(type)
    end

    # what do we do when recurring transies have their own custom
    # views while deposits & withdrawals share the same ones?
    # i know i no
    # we HACXs:
    view_prefix = case type
    when 'recurrings'; '/transactions/recurrings'
    else; '/transactions'
    end

    get "/new" do
      @tx = @account.send(type).new
      erb :"#{view_prefix}/new" # ^ hack in place
    end

    get "/:tid/edit" do |tid|
      unless @tx = @account.send(type).get(tid)
        halt 400, "No such transaction."
      end

      erb :"#{view_prefix}/edit"
    end

    # Populates a transaction with fields found in the request params.
    # Handles both newly created (not yet saved) and persistent resources.
    # However, it does _not_ update or save the resource, which is why it's
    # called a populator and not a builder.
    #
    # Accepted params:
    #
    # => amount: Float
    # => currency: String (see Currency)
    # => note: Text
    # => occured_on: String (MM/DD/YYYY)
    # => payment_method: Integer (id)
    # => categories: Array of category ids (strings or integers, doesn't matter)
    #
    # For Recurring transies:
    # => flow_type: one of [ 'positive', 'negative' ]
    # => frequency: one of [ 'daily', 'monthly', 'yearly' ]
    # => if frequency == monthly
    #   => monthly_recurs_on_day: Integer, day of the month the tx should reoccur on
    # => if frequency == yearly
    #   => yearly_recurs_on_day: Integer, day of the year the tx should reoccur on
    #   => yearly_recurs_on_month: Integer, month of the year the tx should reoccur on
    # }
    #
    # @return: the passed transie
    #
    def populate_transie(tx)
      tx.amount     = params[:amount].to_f        if params.has_key?('amount')
      tx.currency   = params[:currency]           if params.has_key?('currency')
      tx.note       = params[:note]               if params.has_key?('note')
      tx.occured_on = params[:occured_on].to_date if params.has_key?('occured_on')

      if params.has_key?('payment_method')
        tx.payment_method = @user.payment_methods.get(params[:payment_method].to_i)
      end

      if tx.recurring?
        tx.flow_type = params[:flow_type].to_sym if params.has_key?('flow_type')

        if params.has_key?('frequency')
          tx.frequency = params[:frequency].to_sym

          case tx.frequency
          when :monthly
            # only the day is used in this case
            if params.has_key?('monthly_recurs_on_day')
              tx.recurs_on = DateTime.new(0, 1, params[:monthly_recurs_on_day].to_i)
            end
          when :yearly
            # the day and month are used in this case
            if params.has_key?('yearly_recurs_on_day') && params.has_key?('yearly_recurs_on_month')
              tx.recurs_on = DateTime.new(0,
                params[:yearly_recurs_on_month].to_i,
                params[:yearly_recurs_on_day].to_i)
            end
          end # tx.frequency types
        end # has frequency
      end # is recurring

      tx
    end # populate_transies

    def attach_transie_categories(tx, category_ids)
      if category_ids && category_ids.is_a?(Array) && category_ids.any?
        category_ids.each { |cid| tx.categories << @user.categories.get(cid) }
      end

      tx
    end

    post  do
      tx = populate_transie(@account.send(type).new)

      if tx.save && tx.saved?
        # t.account.save!
        flash[:notice] = "Transaction created."

        # attach to categories
        attach_transie_categories(tx, params[:categories]).save
      else
        flash[:error] = tx.all_errors
      end

      redirect back
    end

    put "/:tid" do |tid|
      unless tx = @account.transactions.get(tid)
        halt 400, "No such transie"
      end

      populate_transie(tx)
      attach_transie_categories(tx, params[:categories])

      if tx.save
        flash[:notice] = "Transaction #{tx.id} was updated successfully."
      else
        flash[:error] = "Transaction #{tx.id} could not be updated: #{tx.collect_errors}, #{tx.account.collect_errors}."
      end

      redirect back
    end

    delete "/:tid" do |tid|
      unless t = @account.transactions.get(tid)
        halt 400, 'No such transie'
      end

      unless t.destroy
        flash[:error] = t.collect_errors
        return redirect back
      end

      flash[:notice] = "Transaction was successfully removed."

      redirect back
    end

    # ----
    # recurring transaction specific routes
    if type == 'recurrings'
      get do
        current_page("manage")

        @transies = current_account.recurrings.all
        @daily_transies   = @transies.all({ frequency: :daily })
        @monthly_transies = @transies.all({ frequency: :monthly })
        @yearly_transies  =  @transies.all({ frequency: :yearly })

        erb :"/transactions/recurrings/index"
      end

      get '/:id/toggle_activity' do |tid|
        unless tx = current_account.recurrings.get(tid)
          halt 400, "No such recurring transaction."
        end

        if tx.update({ active: !tx.active? })
          if tx.active?
            flash[:notice] = "The recurring transaction #{tx.note} will once again recur."
          else
            flash[:notice] = "The recurring transaction #{tx.note} will no longer recur."
          end
        else
          flash[:error] =  "Something went wrong while updating the transaction, "
          flash[:error] += "here's the technical response: #{tx.collect_errors}."
        end

        redirect back
      end
    end

  end # namespace
end # transie type loop



helpers do
  def render_transactions_for(year = Time.now.year, month = Time.now.month, day = Time.now.day)
    year  = year.to_i   if year.is_a? String
    month = month.to_i  if month.is_a? String
    day   = day.to_i    if day.is_a? String

    # make sure the given date is sane
    begin
      @date = Time.new(year, month == 0 ? 1 : month, day == 0 ? 1 : day)
    rescue ArgumentError => e
      halt 400, "Invalid transaction period YYYY/MM/DD: '#{year}/#{month}/#{day}'"
    end

    current_page("transactions")

    if day > 0
      # daily transaction view
      @drilldown = "daily"

      @transies = current_account.daily_transactions(Time.new(year,month,day))
      @drilled_transies = { "0" => @transies }
    elsif month > 0
      # monthly transaction view
      @drilldown = "monthly"
      @transies = current_account.monthly_transactions(Time.new(year, month, 1))

      # partition into days
      @drilled_transies = {}
      @transies.each { |tx|
        @drilled_transies[tx.occured_on.day] ||= []
        @drilled_transies[tx.occured_on.day] <<  tx
      }
    else
      # yearly transaction view
      @drilldown = "yearly"
      @transies = current_account.yearly_transactions(Time.new(year, 1, 1))

      # partition into months
      @drilled_transies = {}#Array.new(13, [])
      @transies.each { |tx|
        @drilled_transies[tx.occured_on.month] ||= []
        @drilled_transies[tx.occured_on.month] <<  tx
      }
    end

    @balance  = current_account.balance_for(@transies)

    erb :"transactions/drilldowns/#{@drilldown}"
  end
end

get '/transactions/:year', auth: :user do |year|
  render_transactions_for(year, 0, 0)
end

get '/transactions/:year/:month', auth: :user do |year, month|
  render_transactions_for(year,month,0)
end

get '/transactions/:year/:month/:day', auth: :user do |year, month, day|
  render_transactions_for(year,month,day)
end