
[ 'deposits', 'withdrawals', 'recurrings' ].each do |type|

  get "/transactions/#{type}/new", auth: :user do
    begin
      # see if there's a custom form for this transaction type (ie, recurrings)
      erb :"transactions/#{type}/new"
    rescue
      # nope, use the generic one
      erb :"transactions/new"
    end
  end

  post "/transactions/#{type}", auth: :user do

    { "You must specify an amount" => params["amount"].empty? }.each_pair {|msg,cnd|
      if cnd
        flash[:error] = msg
        return redirect back
      end
    }

    c = case type
      when 'deposits' then @account.deposits
      when 'withdrawals' then @account.withdrawals
      when 'recurrings' then @account.recurrings
    end

    t = c.create({
      amount: params["amount"].to_f,
      currency: params["currency"].to_s,
      note: params["note"],
      account: @account
    })

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
    unless t = @account.transactions.get(tid)
      halt 400
    end

    t.amount = params["amount"] if params.has_key?("amount")
    t.currency = params["currency"] if params.has_key?("currency")

    unless t.save
      halt 500, t.collect_errors
    end

    t
  end

  delete "/transactions/#{type}/:tid", auth: :user do |tid|
    unless t = @account.transactions.get(tid)
      halt 400
    end

    unless t.destroy
      halt 500, t.collect_errors
    end

    true
  end

end