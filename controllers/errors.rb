not_found do
  if request.xhr?
    r = response.body.first
    return r.include?("<html>") ? "404 - bad link!" : r.to_json
  end

  erb :"404", layout: set_layout
end

error 401 do
  if request.xhr?
    r = response.body.first
    return r.include?("<html>") ? "401 - unauthorized!" : r.to_json
  end

  erb :"401", layout: set_layout
end

error 403 do
  if request.xhr?
    r = response.body.first
    return r.include?("<html>") ? "403 - forbidden!" : r.to_json
  end

  erb :"403", layout: set_layout
end

error 400 do
  erb :"400", layout: set_layout
end

error 500 do
  if request.xhr?
    halt 500, "500 - internal error: " + env['sinatra.error'].name + " => " + env['sinatra.error'].message
  end

  erb :"500", layout: set_layout
end