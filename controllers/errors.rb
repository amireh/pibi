not_found do
  if request.xhr?
    r = response.body.first
    return r.include?("<html>") ? "404 - bad link!" : r.to_json
  end

  erb :"404"
end

error 401 do
  if request.xhr?
    r = response.body.first
    return r.include?("<html>") ? "401 - unauthorized!" : r.to_json
  end

  erb :"401"
end

error 403 do
  if request.xhr?
    r = response.body.first
    return r.include?("<html>") ? "403 - forbidden!" : r.to_json
  end

  erb :"403"
end

error 400 do
  erb :"400"
end

error 500 do
  if request.xhr?
    halt 500, "500 - internal error: " + env['sinatra.error'].name + " => " + env['sinatra.error'].message
  end

  erb :"500"
end