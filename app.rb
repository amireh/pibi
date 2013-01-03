# encoding: UTF-8

$ROOT ||= File.dirname(__FILE__)
$LOAD_PATH << $ROOT

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

require 'config/initializer'

configure do
  config_file 'config/application.yml'
  config_file 'config/credentials.yml'
  config_file 'config/database.yml'

  use Rack::Session::Cookie, :secret => settings.credentials['cookie']['secret']
  use OmniAuth::Builder do
    OmniAuth.config.on_failure = Proc.new { |env|
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    }

    provider :developer if settings.development?
    provider :facebook, settings.credentials['facebook']['key'], settings.credentials['facebook']['secret']
    provider :twitter,  settings.credentials['twitter']['key'],  settings.credentials['twitter']['secret']
  end

  dbc = settings.database
  # DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, "mysql://#{dbc[:un]}:#{dbc[:pw]}@#{dbc[:host]}/#{dbc[:db]}")

  # load everything
  [ 'lib', 'helpers', 'models', 'controllers' ].each { |d|
    Dir.glob("#{d}/**/*.rb").each { |f| require f }
  }

  DataMapper.finalize
  DataMapper.auto_upgrade!

  set :config_path, File.join($ROOT, "config")
  set :default_preferences, JSON.parse(File.read(File.join(settings.config_path, "preferences.json")))

  Pony.options = {
    :from => settings.courier[:from],
    :via => :smtp,
    :via_options => {
      :address    => settings.credentials['courier']['address'],
      :port       => settings.credentials['courier']['port'],
      :user_name  => settings.credentials['courier']['key'],
      :password   => settings.credentials['courier']['secret'],
      :enable_starttls_auto => true,
      :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
      :domain => "HELO", # don't know exactly what should be here
    }
  }

  Currencies = Currency.all_names

  helpers Gravatarify::Helper

  # Gravatarify.options[:default] = "wavatar"
  Gravatarify.options[:filetype] = :png
  Gravatarify.styles.merge!({
    mini:     { size: 16, html: { :class => 'gravatar gravatar-mini' } },
    icon:     { size: 32, html: { :class => 'gravatar gravatar-icon' } },
    default:  { size: 96, html: { :class => 'gravatar' } },
    profile:  { size: 128, html: { :class => 'gravatar' } }
  })

end

configure :production do
  Bundler.require(:production)
end

configure :development do
  Bundler.require(:development)
end
