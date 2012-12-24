get '/categories', auth: :user do
  erb :"categories/index"
end

post '/categories', auth: :user do

  { "You must specify a name" => params["name"].empty? }.each_pair {|msg,cnd|
    if cnd
      flash[:error] = msg
      return redirect back
    end
  }

  if @user.categories.first({ name: params["name"] })
    flash[:error] = "You already have a category called #{params["name"]}"
    return redirect back
  end

  c = @user.categories.create({
    name: params["name"].to_s
  })

  if c.saved?
    flash[:notice] = "Category created."
  else
    flash[:error]  = c.collect_errors
  end

  redirect back
end

put '/categories/:cid', auth: :user do |cid|
  unless c = @user.categories.get(cid)
    halt 400
  end

  if params.has_key?("name")

    # must be unique
    if @user.categories.first({ name: params["name"] })
      halt 400, "You already have a category called #{params["name"]}."
    end

    c.name = params["name"] if params.has_key?("name")
  end
  
  unless c.save
    halt 500, c.collect_errors
  end

  c
end

delete '/categories/:cid', auth: :user do |cid|
  unless c = @account.categories.get(cid)
    halt 400
  end

  unless c.destroy
    halt 500, c.collect_errors
  end

  true
end