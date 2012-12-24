# encoding: UTF-8

$ROOT ||= File.dirname(__FILE__)
$LOAD_PATH << $ROOT

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

require 'config/initializer'
require 'config/credentials'

configure :development do
  Bundler.require(:development)
end

configure :production do
  Bundler.require(:production)

  use OmniAuth::Builder do
    provider :developer if settings.development?
    provider :facebook,
      Credentials[:facebook][:key],
      Credentials[:facebook][:secret]
    provider :twitter,
      Credentials[:twitter][:key],
      Credentials[:twitter][:secret]
    provider :google_oauth2,
      Credentials[:google][:key],
      Credentials[:google][:secret],
      { access_type: 'online', approval_prompt: '' }
    # provider :openid, :store => OpenID::Store::Filesystem.new(File.join($ROOT, 'tmp'))
  end

  Pony.options = {
    :from => "noreply@#{AppURL}",
    :via => :smtp, :via_options => {
      :address => 'smtp.gmail.com',
      :port => '587',
      :enable_starttls_auto => true,
      :user_name  => Credentials[:gmail][:key],
      :password   => Credentials[:gmail][:secret],
      :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
      :domain => "HELO", # don't know exactly what should be here
    }
  }

end

configure do
  # enable :sessions
  use Rack::Session::Cookie, :secret => Credentials[:cookie][:secret]

  helpers Gravatarify::Helper

  # Gravatarify.options[:default] = "wavatar"
  Gravatarify.options[:filetype] = :png
  Gravatarify.styles.merge!({
    mini:     { size: 16, html: { :class => 'gravatar gravatar-mini' } },
    default:  { size: 96, html: { :class => 'gravatar' } },
    profile:  { size: 128, html: { :class => 'gravatar' } }
  })

  # DataMapper::Logger.new($stdout, :debug)

  dbc = JSON.parse(File.read(File.join($ROOT, 'config', 'database.json')))
  dbc = dbc[settings.environment.to_s] || dbc["production"]
  # DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, "mysql://#{dbc['username']}:#{dbc['password']}@localhost/#{dbc['db']}")

  # load the models and controllers
  def load_all(directory)
    Dir.glob("#{directory}/*.rb").each { |f| require f }
  end

  load_all "lib"
  load_all "helpers"
  load_all "models"
  load_all "controllers"

  #  require 'controllers/sessions'
  #  require 'controllers/users'
  #  require 'controllers/transactions'
  #  require 'controllers/categories'

  DataMapper.finalize
  DataMapper.auto_upgrade!

  set :config_path, File.join($ROOT, "config")
  set :default_preferences, JSON.parse(File.read(File.join(settings.config_path, "preferences.json")))

  Currencies = Currency.all_names
end

before do
  @layout = "layouts/#{logged_in? ? 'primary' : 'guest' }".to_sym
end

not_found do
  if request.xhr?
    r = response.body.first
    return r.include?("<html>") ? "404 - bad link!" : r.to_json
  end

  erb :"404"
end

error 403 do
  if request.xhr?
    r = response.body.first
    return r.include?("<html>") ? "403 - forbidden!" : r.to_json
  end

  erb :"403"
end

# error do
#   if request.xhr?
#     halt 500, "500 - internal error: " + env['sinatra.error'].name + " => " + env['sinatra.error'].message
#   end

#   erb :"500"
# end

get '/' do
  pass unless logged_in?

  erb "transactions/index"
end

get '/' do
  erb "welcome/index"
end