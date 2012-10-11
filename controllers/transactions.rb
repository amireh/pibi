
# [ 'deposit', 'withdrawal' ].each do |type|

  get '/accounts/:account/transactions/deposits/new', auth: :user do |account|
    erb :"transactions/new"
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

# end