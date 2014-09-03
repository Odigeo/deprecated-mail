require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
#require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Mail
  class Application < Rails::Application
    # Defaults for generators
    config.generators do |g|
      g.assets false
      g.stylesheets false
      g.helper false
      g.test_framework :rspec, :fixture => true
      g.fixture_replacement :factory_girl    
    end
    
    # Turn off sessions
    config.session_store :disabled
    config.middleware.delete ActionDispatch::Cookies
    
    # Handle our own exceptions internally, so we can return JSON error bodies
    config.exceptions_app = ->(env) { ErrorsController.action(:show).call(env) }
    
    # Disable the asset pipeline
    config.assets.enabled = false    
    
    # No locales
    config.i18n.enforce_available_locales = false    
    
    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :credentials]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    f = File.join(Rails.root, "config/smtp.yml")
    if File.exists?(f)
      config.action_mailer.smtp_settings = YAML.load(File.read(f))['smtp'].symbolize_keys
    end
  end
end
