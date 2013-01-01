class PaymentMethod
  include DataMapper::Resource

  Colors = [ 'EF7901', '98BF0D', 'D54421', '01B0EC', '7449F1', 'B147A3' ]

  property :id, Serial

  property :name, String, length: 50, required: true
  property :default, Boolean, default: false
  property :color, String, length: 6, default: lambda { |*| Colors[rand(Colors.size)] }

  belongs_to :user
  has n, :transactions, :constraint => :set_nil

  def colorize
    self.update({ color: Colors[rand(Colors.size)] })
  end
end