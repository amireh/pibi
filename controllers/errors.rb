def handle_json_error
  content_type :json
  status response.status

  { :result => 'error', :message => response.body }.to_json
end

not_found do
  return handle_json_error if response.content_type && response.content_type.include?('json')

  if request.xhr?
    r = response.body.first
    return !r || r.include?("<html>") ? "404 - bad link!" : r.to_json
  end

  erb :"404", layout: set_layout
end

error 401 do
  return handle_json_error if response.content_type && response.content_type.include?('json')

  if request.xhr?
    r = response.body.first
    return !r || r.include?("<html>") ? "401 - unauthorized!" : r.to_json
  end

  erb :"401", layout: set_layout
end

error 403 do
  return handle_json_error if response.content_type && response.content_type.include?('json')

  if request.xhr?
    r = response.body.first
    return !r || r.include?("<html>") ? "403 - forbidden!" : r.to_json
  end

  erb :"403", layout: set_layout
end

error 400 do
  return handle_json_error if response.content_type && response.content_type.include?('json')

  erb :"400", layout: set_layout
end

error 500 do
  return handle_json_error if response.content_type && response.content_type.include?('json')

  if request.xhr?
    halt 500, "500 - internal error: " + env['sinatra.error'].name + " => " + env['sinatra.error'].message
  end

  erb :"500", layout: set_layout
end
