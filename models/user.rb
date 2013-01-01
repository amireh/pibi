require 'resolv'

class User
  include DataMapper::Resource

  property :id, Serial

  property :name,     String, length: 255, required: true
  property :provider, String, length: 255, required: true
  property :uid,      String, length: 255, required: true

  property :email,          String, length: 255, default: "", unique: true
  property :email_verified, Boolean, default: false
  property :gravatar_email, String, length: 255, default: lambda { |r,_| r.email }
  property :nickname,       String, length: 120, default: ""
  property :password,       String, length: 64, required: true
  property :settings,       Text, default: "{}"
  property :oauth_token,    Text
  property :oauth_secret,   Text
  property :extra,          Text
  property :auto_password,  Boolean, default: false
  property :auto_nickname,  Boolean, default: false
  property :created_at,     DateTime, default: lambda { |*_| DateTime.now }
  property :is_admin,       Boolean, default: false

  has n, :notices, :constraint => :destroy
  has n, :accounts, :constraint => :destroy
  # has n, :transactions, :through => :accounts
  # has n, :deposits,     :through => :accounts
  has n, :categories, :constraint => :destroy
  has n, :payment_methods, :constraint => :destroy
  has 1, :payment_method, :constraint => :skip

  validates_presence_of :name, :provider, :uid

  before :valid? do |_|
    if self.nickname.empty?
      self.nickname = name.to_s.sanitize
    end

    unless email_verified?
      validate_email!
    end


    true
  end

  after :create do
    self.accounts.create
    self.payment_methods.create({ name: "Cash" })
    self.payment_methods.create({ name: "Cheque" })
  end

  def notice_count
    notices.all({status: :pending }).count
  end

  def categories
    Category.all({ conditions: { user_id: id }, :order => [ :name.asc ] })
  end

  def namespace
    ""
  end

  def on_notice_accepted(notice)
    case notice.type
    when 'email'
      update({ email_verified: true })
    when 'password'
      # nothing to do really
    end
  end

  def on_notice_expired(notice)
    notice.destroy
  end

  # Email verification:
  #
  # the deal here is that a Notice is sent to the user's registered email
  # address containing a link which, when visited, will verify the address
  def email_verified?
    email_verified
  end

  # dispatches an email verification notice notice
  def verify_email
    unless n = notices.first_or_create({ data: self.email, type: 'email' })
      errors.add :notices, n.collect_errors
      throw :halt
    end

    n
  end

  # has a notice been dispatched and is still pending?
  def awaiting_email_verification?
    if email_verified?
      return false
    end

    return !notices.all({ type: 'email', status: :pending }).empty?
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

  # Validates whether the given string is a valid and genuine email address
  def validate_email!
    unless email.nil? || email.empty?
      unless email.is_email?
        errors.add(:email, "Your email address does not appear to be valid.")
        throw :halt
      else
        unless validate_email_domain(email)
          errors.add(:email, "Your email domain name appears to be incorrect.")
          throw :halt
        end
      end
    end
  end

end