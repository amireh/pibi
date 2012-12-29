helpers do

  # Used in the generation of email verification links
  def __host
    request.referer.scan(/http:\/\/[^\/]*\//).first[0..-2]
  end

  # Loads the user's preferences merging them with the defaults
  # for any that were not overridden.
  #
  # Side-effects:
  # => @preferences will be overridden with the current user's settings
  def preferences(user = nil)
    user ||= current_user

    if !user
      return settings.default_preferences
    elsif @preferences
      return @preferences
    end

    @preferences = {}
    prefs = user.settings
    if prefs && !prefs.empty?
      begin; @preferences = JSON.parse(prefs); rescue; @preferences = {}; end
    end

    defaults = settings.default_preferences.dup
    @preferences = defaults.deep_merge(@preferences)
    @preferences
  end

  def pretty_time(datetime)
    datetime.strftime("%D")
  end

  def tx_to_html(t)
    "[ #{t.withdrawal? ? '-' : '+'} ] #{t.currency} #{t.amount.to_f} #{t.categories.collect { |c| c.name }} on #{pretty_time t.occured_on} - #{t.note}"
  end

  def natural_recurrence_date(recurring_tx)
    case recurring_tx.frequency
    when :monthly; "The #{recurring_tx.recurs_on.day.ordinalize} of every month"
    when :yearly;  "The #{recurring_tx.recurs_on.day.ordinalize} of #{recurring_tx.recurs_on.strftime("%B")}"
    end
  end

  def to_jQueryUI_date(d)
    d.strftime("%m/%d/%Y")
  end

  def actions_for(tx)
    html = ''
    html << "<a href=\"#{tx.url}/edit\">Edit</a>"
    html << " <a href=\"#{tx.url}/destroy\">Delete</a>"
    if tx.recurring?
      action = tx.active? ? 'Deactivate' : 'Activate'
      html << " <a href=\"#{tx.url}/toggle_activity\">#{action}</a>"
    end
    html
  end
end