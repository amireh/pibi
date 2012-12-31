class PaymentMethod
  include DataMapper::Resource

  property :id, Serial

  property :name, String, length: 50
  belongs_to :user
end