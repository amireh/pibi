class Category
  include DataMapper::Resource

  property :id, Serial

  property :name, String, length: 250, required: true, message: 'You must provide a name for the category!'
  belongs_to :user
  has n, :transactions, :through => Resource, :constraint => :skip

  before :destroy do
    CategoryTransaction.all({ category_id: self.id }).destroy
  end

  def url
    "/categories/#{id}"
  end
end