class Category
  include DataMapper::Resource

  property :id, Serial

  property :name, String, length: 250,
    unique: :user_id,
    required: true,
    messages: {
      presence: 'You must provide a name for the category!',
      is_unique: 'You already have such a category!'
    }

  belongs_to :user, required: true
  has n, :transactions, :through => Resource, :constraint => :skip

  before :destroy do
    CategoryTransaction.all({ category_id: self.id }).destroy
  end

  is :locatable

  def url
    "/categories/#{id}"
  end

  def test
    relationships
  end
end