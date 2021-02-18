require './lib/message_sender'
require './lib/mirrorz'

class MessageResponder
  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
    @user = @message.from
    @mirrorz = options[:mirrorz]
  end

  def respond
    on %r{^/start$} do
      answer_with_greeting_message
    end

    on %r{^/help$} do
      answer_with_help_message
    end

    on %r{^/sync_sites$} do
      @mirrorz.sync_sites
    end

    on %r{^/sites$} do
      answer_with_sites
    end

    on %r{^/site\s\[([^\[\]]+?)\]$} do |index_or_abbr|
      answer_with_site(index_or_abbr)
    end

    on %r{^/items$} do
      answer_with_items
    end

    on %r{^/item\s\[([^\[\]]+?)\]$} do |regex|
      answer_with_item(regex)
    end

    on %r{^/item\s\[([^\[\]]+?)\]\s\[([^\[\]]+?)\]$} do |regex, index_or_abbr|
      answer_with_item_site(regex, index_or_abbr)
    end
  end

  private

  def on(regex, &block)
    regex =~ @message.text
    return unless $~

    if block.arity.zero?
      yield
    else
      yield(*(1...(1 + block.arity)).map { |i| Regexp.last_match(i) })
    end
  rescue StandardError => e
    $log.error(e.backtrace)
    answer_with_message(I18n.t('internal_error'))
  end

  def answer_with_greeting_message
    answer_with_message(I18n.t('greeting_message'))
  end

  def answer_with_help_message
    answer_with_message(I18n.t('help_message'), 'MarkdownV2')
  end

  def answer_with_sites
    answer_with_message("#{I18n.t('mirrorz.site.abbr')}   -   #{I18n.t('mirrorz.site.name')}\n" +
    @mirrorz.sites.map do |site|
      "`[#{site[:abbr]}]` - [#{site[:name]}](#{site[:url]})"
    end.join("\n"), 'Markdown')
  end

  def answer_with_site(index_or_abbr)
    index = @mirrorz.sites.index { |site| site[:abbr] == index_or_abbr } || Integer(index_or_abbr)
    answer_with_message(@mirrorz.sites[index].each_pair.map do |k, v|
      "#{I18n.t("mirrorz.site.#{k}")}: #{v}"
    end.join("\n"))
  rescue StandardError
    answer_with_message(I18n.t('not_found'))
  end

  def answer_with_items
    answer_with_message("#{I18n.t('mirrorz.info.category')} - #{I18n.t('mirrorz.info.distro')}\n" +
    @mirrorz.items.map do |item|
      "#{item[:category]} - #{item[:distro]}"
    end.join("\n"), 'Markdown')
  end

  def find_item(regex)
    index = @mirrorz.items.index { |item| /#{regex}/i.match(item[:distro]) } || Integer(regex)
    @mirrorz.items[index]
  end

  def answer_with_item(regex)
    item = find_item(regex)
    answer_with_message("#{item[:category]} - #{item[:distro]}\n\n" +
      item[:sites].map do |site|
        "`[#{site[:abbr]}]` - #{site[:name]}"
      end.join("\n"),  'Markdown')
  rescue StandardError
    answer_with_message(I18n.t('not_found'))
  end

  def answer_with_item_site(regex, index_or_abbr)
    item = find_item(regex)
    sites = item[:sites]
    index = sites.index { |site| site[:abbr] == index_or_abbr } || Integer(index_or_abbr)
    answer_with_message(sites[index][:items].to_yaml)
  rescue StandardError
    answer_with_message(I18n.t('not_found'))
  end

  def answer_with_message(text, parse_mode = nil)
    MessageSender.new(bot: @bot, chat: @message.chat, text: text, parse_mode: parse_mode).send
  end
end
