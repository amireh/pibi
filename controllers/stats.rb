route_namespace '/users/:user_id/stats' do
  condition do
    restrict_to(:user, { with: { :id => params[:user_id].to_i } })
  end

  def transactions_in(b, e, q = {}, r = nil)
    begin
      b = b.to_date(false)
      e = e.to_date(false)
    rescue ArgumentError => e
      halt 400, "Invalid date range in [#{b}, #{e}]. Accepted format: MM-DD-YYYY"
    end

    (r || current_account).transactions_in({ :begin => b, :end => e }, q)
  end

  # Stat structure:
  #   [...,
  #    {
  #     name:  string,
  #     color: string,
  #     ratio: float,
  #     count: integer
  #    },
  #   ...]
  get '/payment_methods/ratio.json' do
    content_type :json

    halt 400, "Missing :begin and :end date range arguments." unless params[:begin] && params[:end]

    s = []

    transies = transactions_in(params[:begin], params[:end])

    if @user.payment_methods.any? && transies.count > 0
      @user.payment_methods.each do |pm|
        pm_transies = transactions_in(params[:begin], params[:end], {}, pm)
        s << {
          name:  pm.name,
          color: pm.color,
          ratio: pm_transies.count.to_f / transies.count * 100.0,
          count: pm_transies.count
        }
      end
    end

    s.to_json
  end

end