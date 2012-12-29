[ 'deposits', 'withdrawals', 'recurrings' ].each do |type|

  get "/transactions/#{type}/new", auth: :user do
    current_page(type)

    @tx = @account.send(type).new
    begin
      # see if there's a custom form for this transaction type (ie, recurrings)
      erb :"transactions/#{type}/new"
    rescue Errno::ENOENT => e
      # nope, use the generic one
      erb :"transactions/new"
    end
  end

  get "/transactions/#{type}/:tid/edit", auth: :user do |tid|
    current_page(type)

    unless @tx = @account.send(type).get(tid)
      halt 400, "No such transaction."
    end

    begin
      # see if there's a custom form for this transaction type (ie, recurrings)
      erb :"transactions/#{type}/edit"
    rescue Errno::ENOENT => e
      # nope, use the generic one
      erb :"transactions/edit"
    end
  end

  post "/transactions/#{type}", auth: :user do
    { "You must specify an amount" => params["amount"].empty? }.each_pair {|msg,cnd|
      if cnd
        flash[:error] = msg
        return redirect back
      end
    }

    c = @account.send(type)
    p = {}

    if type == 'recurrings' then
      # validate parameters
      puts "inb4 recurrings"
      unless ['positive','negative'].include? params[:flow_type]
        puts "bad flow type"
        halt 400, "flow_type must be either 'positive' or 'negative', got #{params[:flow_type]}."
      end

      unless ['daily', 'monthly', 'yearly'].include? params[:frequency]
        puts "bad frequency"
        halt 400, "frequency must be one of 'daily', 'monthly', or 'yearly', got #{params[:frequency]}."
      end

      p = {
        active: true,
        flow_type: params[:flow_type].to_sym,
        frequency: params[:frequency].to_sym
      }

      if p[:frequency] == :monthly
        # only the day is used in this case
        p[:recurs_on] = DateTime.new(0, 1, params[:monthly_recurs_on_day].to_i)
      elsif p[:frequency] == :yearly
        # the day and month are used in this case
        p[:recurs_on] = DateTime.new(0, params[:yearly_recurs_on_month].to_i, params[:yearly_recurs_on_day].to_i)
      end
    end

    if params["occured_on"]
      p[:occured_on] = params["occured_on"].to_date
    end

    t = c.create({
      amount: params["amount"].to_f,
      currency: params["currency"].to_s,
      note: params["note"],
      account: @account
    }.merge(p))

    if t.saved?
      flash[:notice] = "Transaction created."

      if params["categories"] && params["categories"].any?
        params["categories"].each { |cid| t.categories << Category.get(cid) }
        t.save
      end
    else
      flash[:error] = t.collect_errors
    end

    redirect back
  end


  put "/transactions/#{type}/:tid", auth: :user do |tid|
    unless tx = @account.transactions.get(tid)
      halt 400
    end

    def update(tx, params, fields)
      fields = [ fields ] unless fields.is_a?(Array)
      fields.each { |field|
        tx.send("#{field}=", params[field]) if params.has_key?(field)
      }
    end

    update(tx, params, [ 'amount', 'currency', 'note' ])

    if params["occured_on"]
      tx.occured_on = params["occured_on"].to_date
    end

    if tx.recurring?
      tx.flow_type = params["flow_type"].to_sym if params.has_key?("flow_type")
      if params.has_key?("frequency")
        tx.frequency = params["frequency"].to_sym
        if tx.frequency == :monthly
          # only the day is used in this case
          tx.recurs_on = DateTime.new(0, 1,
            params["monthly_recurs_on_day"].to_i)
        elsif tx.frequency == :yearly
          # the day and month are used in this case
          tx.recurs_on = DateTime.new(0,
            params["yearly_recurs_on_month"].to_i,
            params["yearly_recurs_on_day"].to_i)
        end
      end
    end

    tx.categories = []
    params["categories"] && params["categories"].each { |cid|
      tx.categories << current_user.categories.get(cid)
    }

    unless tx.valid?
      flash[:error] = "Transaction #{tx.id} could not be updated: #{tx.collect_errors}, #{tx.account.collect_errors}."
      # halt 500, tx.collect_errors
    else
      tx.save
      tx.account.save!
      flash[:notice] = "Transaction #{tx.id} was updated successfully."
    end

    redirect back
  end

  delete "/transactions/#{type}/:tid", auth: :user do |tid|
    unless t = @account.transactions.get(tid)
      halt 400
    end

    unless t.destroy
      halt 500, t.collect_errors
    end

    flash[:notice] = "Transaction was successfully removed."

    redirect back
  end
end

get '/transactions/recurrings', auth: :user do
  current_page("manage")

  @transies = current_account.recurrings.all
  erb :"/transactions/recurrings/index"
end

get '/transactions/recurrings/:id/toggle_activity', auth: :user do |tid|
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