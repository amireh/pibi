helpers do
  def format_top_categories(categories)
    upper_bound = categories.length < 2 ? categories.length : 2
    natural_join(categories[0..upper_bound].collect { |c| c.name }, ', ', ', and ', [ '<span class="big">', '</span>' ])
  end
end