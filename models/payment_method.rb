class PaymentMethod
  include DataMapper::Resource

  default_scope(:default).update(:order => [ :name.asc ])

  Colors = [ 'EF7901', '98BF0D', 'D54421', '01B0EC', '7449F1', 'B147A3' ]

  belongs_to :user, required: true

  property :id, Serial
  property :name, String, length: 50, required: true,
    unique: :user_id,
    messages: {
      presence: 'Payment method requires a name!',
      is_unique: 'A payment method with that name already exists.'
    }
  property :default, Boolean, default: false, unique: :user_id,
    message: 'You already have a default payment method!'
  property :color, String, length: 6, default: lambda { |*| Colors[rand(Colors.size)] }

  has n, :transactions, :constraint => :set_nil

  def colorize
    self.update({ color: Colors[rand(Colors.size)] })
  end
end