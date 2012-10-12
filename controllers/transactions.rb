
# [ 'deposit', 'withdrawal' ].each do |type|

  get '/accounts/:account/transactions/deposits/new', auth: :user do |account|
    erb "transactions/new"
  end

  post '/accounts/:account/transactions/deposits', auth: :user do |account|
    puts params.inspect

    t = @account.transactions.create({
      amount: params["amount"].to_f,
      currency: params["currency"].to_s,
      type: 'Deposit'
    })
    unless t.valid? && t.persistent?
      flash[:error] = t.collect_errors
    else
      flash[:notice] = "Transie stored: #{t.collect_errors}."
    end

    redirect back
  end

  put '/accounts/:account/transactions/deposits/:tid', auth: :user do |a,tid|
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

  delete '/accounts/:account/transactions/deposits/:tid', auth: :user do |a,tid|
    unless t = @account.transactions.get(tid)
      halt 400
    end

    unless t.destroy
      halt 500, t.collect_errors
    end

    true
  end

# end