require 'i18n'
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
    I18n.load_path << Dir[File.expand_path('config/locales') + '/*.yml']
    I18n.default_locale = :'zh-CN'
    I18n.backend.load_translations
  end
end
