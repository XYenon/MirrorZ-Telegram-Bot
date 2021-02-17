require './lib/message_sender'
require './lib/mirrorz'

class MessageResponder
  attr_reader :message, :bot, :user

  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
    @user = message.from
    @mirrorz = options[:mirrorz]
  end

  def respond
    on %r{^/start} do
      answer_with_greeting_message
    end

    on %r{^/help} do
      answer_with_help_message
    end

    on %r{^/sync_sites} do
      @mirrorz.sync_sites
    end

    on %r{^/sites} do
      answer_with_sites
    end

    on %r{^/site\s(\w+)} do |index_or_abbr|
      answer_with_site(index_or_abbr)
    end
  end

  private

  def on(regex, &block)
    regex =~ message.text
    return unless $~

    if block.arity.zero?
      yield
    else
      yield(*(1...(1 + block.arity)).map { |i| Regexp.last_match(i) })
    end
  end

  def answer_with_greeting_message
    answer_with_message(I18n.t('greeting_message'))
  end

  def answer_with_help_message
    answer_with_message(I18n.t('help_message'), 'MarkdownV2')
  end

  def answer_with_sites
    answer_with_message(@mirrorz.sites.map.with_index do |site, i|
      "#{i} #{site[:abbr]} #{site[:name]}\n#{site[:url]}"
    end.join("\n\n"))
  end

  def answer_with_site(index_or_abbr)
    index = @mirrorz.sites.index { |site| site[:abbr] == index_or_abbr } || Integer(index_or_abbr)
    answer_with_message(@mirrorz.sites[index].to_yaml)
  rescue StandardError
    answer_with_message(I18n.t('not_found'))
  end

  def answer_with_message(text, parse_mode = nil)
    MessageSender.new(bot: bot, chat: message.chat, text: text, parse_mode: parse_mode).send
  end
end
