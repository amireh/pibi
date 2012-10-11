$ROOT = File.join(File.dirname(__FILE__), '..', '..')
$LOAD_PATH << $ROOT

require "rack/test"
require "webrat"
require "test/unit"
require "app"

Webrat.configure do |config|
  config.mode = :rack
end

class AppTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers

  def app
    Sinatra::Application.new
  end

  def self.it(name, &blk)
    self.send(:define_method, "test_#{name.gsub(/\s/, '_')}", blk)
  end

  before do
    set :show_exceptions, false
    @@fixture = {
      email:    "ahmad@amireh.net",
      name:     "Ahmad Amireh",
      nickname: "bitmask"
    }
  end

  # after do |scenario|
    # puts scenario.inspect
  #   throw :halt
  #   if scenario.failed?# && scenario.exception.is_a?(Webrat::NotFoundError)
  #     save_and_open_page
  #   end
  # end

  private

  def goto_signup(&blk)
    visit "/users/new"
    blk.call if blk
    begin
      click_button "Sign up to Pibi!"
      follow_redirect!
    rescue Exception => e
    end
  end

  def fixture
    @@fixture
  end

  public

  it "should require an email" do
    goto_signup
    assert_have_selector('span', { :class => "flash error" })
    assert_contain("You must fill in your email address")
  end

  it "should require a valid email" do
    goto_signup {
      fill_in "Your email:", with: "foobar"
    }

    assert_have_selector('span', { :class => "flash error" })
    assert_contain("That email doesn't appear to be valid")
  end

  it "should require an available email" do
    # create a mockup user
    email = "foo@bar.com"
    u = User.create({
      email: email,
      password: "foobar",
      uid: 123,
      provider: "pibi",
      name: "Ahmad Amireh",
      nickname: "bitmask"
    })

    goto_signup {
      fill_in "Your email:", with: email
    }

    assert_have_selector('span', { :class => "flash error" })
    assert_contain("That email is already registered")

    u.destroy
  end

  it "should require a name" do
    goto_signup {
      fill_in "Your email:", with: fixture[:email]
    }

    assert_have_selector('span', { :class => "flash error" })
    assert_contain("You must fill in your name")
  end

  it "should ask for a password twice" do
    goto_signup {
      fill_in "Your email:", with: fixture[:email]
      fill_in "Your name:",  with: fixture[:name]
    }

    assert_have_selector('span', { :class => "flash error" })
    assert_contain("You must type the same password twice")
  end

  it "should ask for matching passwords" do
    goto_signup {
      fill_in "Your email:", with: fixture[:email]
      fill_in "Your name:",  with: fixture[:name]
      fill_in "password",  with: "foobar"
      fill_in "password_confirmation",  with: "foo"
    }

    #assert_have_selector('span', { :class => "flash error" })
    #assert_contain("The passwords you entered do not match")
    within '#flashes' do |scope|
      scope.session.assert_have_selector('span', { :class => "flash error" })
      scope.session.assert_contain("The passwords you entered do not match")
    end
  end
end