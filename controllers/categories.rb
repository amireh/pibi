get '/categories', auth: :user do
  current_page("manage")

  erb :"categories/index"
end

get '/categories/:id', auth: :user do |cid|
  current_page("manage")

  unless @c = current_user.categories.first({id: cid})
    error 404, "No such category"
  end

  erb :"categories/show"
end

get '/categories/:id/edit', auth: :user do |cid|
  current_page("manage")

  unless @c = current_user.categories.first({id: cid})
    halt 404, "No such category"
  end

  erb :"categories/edit"
end

post '/categories', auth: :active_user do

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

put '/categories/:cid', auth: :active_user do |cid|
  unless c = @user.categories.get(cid)
    halt 400
  end

  if params.has_key?("name")

    # must be unique
    if @user.categories.first({ name: params["name"] })
      flash[:error] = "You already have a category called #{params["name"]}."
      return redirect back
    end

    c.name = params["name"] if params.has_key?("name")
  end

  unless c.save
    # halt 500, c.collect_errors
    flash[:error] = "Category could not be updated. Technical reason: #{c.collect_errors}"
  else
    flash[:notice] = "The category '#{c.name}' has been updated."
  end

  redirect back
end

delete '/categories/:cid', auth: :active_user do |cid|
  unless c = @user.categories.get(cid)
    halt 400
  end

  name = c.name

  unless c.destroy
    # halt 500, c.collect_errors
    flash[:error] = "Category could not be deleted. Technical reason: #{c.collect_errors}"
  else
    flash[:notice] = "The category '#{name}' has been removed."
  end

  redirect '/categories'
end