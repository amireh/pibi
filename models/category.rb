class Category
  include DataMapper::Resource

  property :id, Serial

  property :name, String, length: 250
  belongs_to :user
  has n, :transactions, :through => Resource, :constraint => :skip

  before :destroy do
    CategoryTransaction.all({ category_id: self.id }).destroy!
    true
  end

  def url
    "/categories/#{id}"
  end
end