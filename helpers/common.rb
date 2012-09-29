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
end