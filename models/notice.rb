class Notice
  include DataMapper::Resource

  property    :id,          Serial
  property    :salt,        String, length: 255
  property    :data,        String, length: 255
  property    :created_at,  DateTime, default: lambda { |*_| DateTime.now }
  property    :type,        String, length: 255
  property    :status,      Enum[ :pending, :expired, :accepted ], default: :pending
  belongs_to  :user

  before :create do |ctx|
    self.salt = Base64.urlsafe_encode64( self.user.nickname + Random.rand(1234).to_s + Time.now.to_s)
    true
  end

  def expired?
    status == :expired
  end

  def pending?
    status == :pending
  end

  def accepted?
    status == :accepted
  end

  def accept!
    update({ status: :accepted })
    user.on_notice_accepted(self)
  end

  def expire!
    update({ status: :expired })
    user.on_notice_expired(self)
  end

  def url
    "/users/#{self.user.id}/accept/#{self.salt}"
  end

end