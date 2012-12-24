[ 'deposits', 'withdrawals', 'recurrings' ].each do |type|

  get "/transactions/#{type}/new", auth: :user do
    @t = @account.send(type).new
    begin
      # see if there's a custom form for this transaction type (ie, recurrings)
      erb :"transactions/#{type}/new"
    rescue Errno::ENOENT => e
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

      puts p
    end

    puts "inb4 creation"
    t = c.create({
      amount: params["amount"].to_f,
      currency: params["currency"].to_s,
      note: params["note"],
      account: @account
    }.merge(p))

    puts "inb4 saving"
    if t.saved?
      flash[:notice] = "Transaction created."

      if params["categories"] && params["categories"].any?
        params["categories"].each { |cid| t.categories << Category.get(cid) }
        t.save
      end
    else
      flash[:error] = t.collect_errors
    end

    puts "inb4 redirect"
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