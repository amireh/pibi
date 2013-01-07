class Category
  include DataMapper::Resource

  default_scope(:default).update(:order => [ :name.asc ])

  property :id, Serial

  property :name, String, length: 250,
    required: true,
    messages: {
      presence: 'You must provide a name for the category!'
    }

  belongs_to :user, required: true
  has n, :transactions, :through => Resource, :constraint => :skip

  validates_uniqueness_of :name, :scope => [ :user_id ],
    message: 'You already have such a category!'

  before :destroy do
    CategoryTransaction.all({ category_id: self.id }).destroy
  end

  # is :locatable

  def url
    "/categories/#{id}"
  end
end