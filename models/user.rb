require 'resolv'

class User
  include DataMapper::Resource

  property :id, Serial

  property :name,     String, length: 255, required: true
  property :provider, String, length: 255, required: true
  property :uid,      String, length: 255, required: true

  property :email,          String, length: 255, default: ""
  property :gravatar_email, String, length: 255, default: lambda { |r,_| r.email }
  property :nickname,       String, length: 120, default: ""
  property :password,       String, length: 64
  property :settings,       Text, default: "{}"
  property :oauth_token,    Text
  property :oauth_secret,   Text
  property :extra,          Text
  property :auto_password,   Boolean, default: false
  property :auto_nickname,  Boolean, default: false
  property :verified,       Boolean, default: false
  property :created_at,     DateTime, default: lambda { |*_| DateTime.now }

  has n, :email_verifications, :constraint => :destroy
  has n, :accounts, :constraint => :destroy
  # has n, :transactions, :through => :accounts
  # has n, :deposits,     :through => :accounts
  has n, :categories, :constraint => :destroy
  has n, :payment_methods, :constraint => :destroy
  has 1, :payment_method, :constraint => :skip

  validates_presence_of :name, :provider, :uid

  before :valid? do |_|
    self.nickname = self.name.to_s.sanitize if self.nickname.empty?

    # unless self.verified
    #   validate_email!(self.email,           "primary")
    #   validate_email!(self.gravatar_email,  "gravatar")
    # end

    true
  end

  after :create do
    self.accounts.create
    self.payment_methods.create({ name: "Cash" })
    self.payment_methods.create({ name: "Cheque" })
  end

  def categories
    Category.all({ conditions: { user_id: id }, :order => [ :name.asc ] })
  end

  def namespace
    ""
  end

  def profile_url
    "/profiles/#{self.nickname}"
  end

  def verified?(address)
    if self.verified
      return true
    elsif address == self.email
      unless ev = self.email_verifications.first({ primary: true })
        return false
      end
    else
      unless ev = self.email_verifications.first({ address: address, primary: false })
        return false
      end
    end

    ev.verified?
  end

  def verify_address(address)
    unless ev = self.email_verifications.first_or_create({ address: address, primary: address == self.email })
      errors.add :email_verifications, ev.collect_errors
      throw :halt
    end

    ev
  end

  def awaiting_verification?(address)
    if ev = self.email_verifications.first({ address: address })
      return ev.pending?
    end
  end

  def self.encrypt(pw)
    Digest::SHA1.hexdigest pw
  end

  private

  # Validates an email domain using Ruby's DNS resolver.
  # Thanks to:
  # => http://www.buildingwebapps.com/articles/79182-validating-email-addresses-with-ruby
  def validate_email_domain(email)
    domain = email.match(/\@(.+)/)[1]
    Resolv::DNS.open do |dns|
      @mx = dns.getresources(domain, Resolv::DNS::Resource::IN::MX)
    end
    @mx.size > 0 ? true : false
  end

  def validate_email!(email, type)
    unless email.nil? || email.empty?
      unless email.is_email?
        errors.add(:email, "Your #{type} email address does not appear to be valid.")
        throw :halt
      else
        unless validate_email_domain(email)
          errors.add(:email, "Your #{type} email domain name appears to be incorrect.")
          throw :halt
        end
      end
    end
  end

end