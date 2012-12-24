
[ 'deposits', 'withdrawals' ].each do |type|

  get "/transactions/#{type}/new", auth: :user do
    erb :"transactions/new"
  end

  post "/transactions/#{type}", auth: :user do

    { "You must specify an amount" => params["amount"].empty? }.each_pair {|msg,cnd|
      if cnd
        flash[:error] = msg
        return redirect back
      end
    }

    c = type == 'deposits' ? @account.deposits : @account.withdrawals
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