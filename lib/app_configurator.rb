require 'i18n'
require 'i18n/backend/fallbacks'
require 'logger'
require 'yaml'

class AppConfigurator
  def initialize
    @config = YAML.safe_load_file('config/config.yml', symbolize_names: true)
  end

  def configure
    setup_i18n
  end

  def token
    @config[:telegram][:bot_token]
  end

  def logger
    Logger.new($stdout, @config[:log][:level])
  end

  private

  def setup_i18n
    I18n::Locale::Tag.implementation = I18n::Locale::Tag::Rfc4646
    I18n::Backend::Simple.include(I18n::Backend::Fallbacks)
    I18n.load_path << Dir[File.expand_path('config/locales') + '/*.yml']
    I18n.default_locale = :'zh-CN'
    I18n.fallbacks = [I18n.default_locale]
    I18n.enforce_available_locales = false
  end
end
