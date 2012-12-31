get '/admin', auth: :admin do
  erb :"/admins/index"
end