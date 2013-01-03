# anonymous vs authenticated view layouts
before do
  @layout = "layouts/#{logged_in? ? 'primary' : 'guest' }".to_sym
end

# authenticated landing page
[ '/', '/transactions' ].each { |r|
  get r do
    pass unless logged_in?

    if params[:year]
      if params[:month]
        if params[:day]
          return redirect "/transactions/#{params[:year]}/#{params[:month]}/#{params[:day]}"
        end
        return redirect "/transactions/#{params[:year]}/#{params[:month]}"
      end
      return redirect "/transactions/#{params[:year]}"
    end

    render_transactions_for(Time.now.year, Time.now.month, 0)
  end
}

# anonymous landing page
get '/' do
  current_page("welcome")

  erb "welcome/index"
end

# static pages
[ 'features', 'tos', 'privacy', 'oss', 'faq' ].each do |static_item|
  get "/#{static_item}" do
    current_page("")
    erb :"static/#{static_item}"
  end
end