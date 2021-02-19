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

    on %r{^/items\s\[([^\[\]]+?)\]$} do |regex|
      answer_with_items(regex)
    end

    on %r{^/item\s\[([^\[\]]+?)\]$} do |distro|
      answer_with_item(distro)
    end

    on %r{^/item\s\[([^\[\]]+?)\]\s\[([^\[\]]+?)\]$} do |distro, index_or_abbr|
      answer_with_item_site(distro, index_or_abbr)
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
    answer_with_message(t('internal_error'))
  end

  def answer_with_greeting_message
    answer_with_message(t('greeting_message'))
  end

  def answer_with_help_message
    answer_with_message(t('help_message'), 'MarkdownV2')
  end

  def answer_with_sites
    answer_with_message("#{t('mirrorz.site.abbr')}   -   #{t('mirrorz.site.name')}\n" +
    @mirrorz.sites.map do |site|
      "`[#{site[:abbr]}]` - [#{site[:name]}](#{@mirrorz.mirrorz_uri(:site, site)})\n#{site[:url]}"
    end.join("\n"), 'Markdown')
  end

  def answer_with_site(index_or_abbr)
    index = @mirrorz.sites.index { |site| site[:abbr] == index_or_abbr } || Integer(index_or_abbr)
    answer_with_message(@mirrorz.sites[index].each_pair.map do |k, v|
      "#{t("mirrorz.site.#{k}")}: #{v}"
    end.join("\n"))
  rescue StandardError
    answer_with_message(t('not_found'))
  end

  def answer_with_items(regex = '.*')
    answer_with_message("#{t('mirrorz.info.category')} - #{t('mirrorz.info.distro')}\n" +
    @mirrorz.items.select { |item| /#{regex}/i.match(item[:distro]) }.map do |item|
      "#{item[:category]} - [#{item[:distro]}](#{@mirrorz.mirrorz_uri(:index, item)})"
    end.join("\n"), 'Markdown')
  end

  def answer_with_item(distro)
    item = @mirrorz.items.find { |i| distro == i[:distro] }
    answer_with_message("#{item[:category]} - [#{item[:distro]}](#{@mirrorz.mirrorz_uri(:index, item)})\n\n" +
      item[:sites].map do |site|
        "`[#{site[:abbr]}]` - #{site[:name]}"
      end.join("\n"),  'Markdown')
  rescue StandardError
    answer_with_message(t('not_found'))
  end

  def answer_with_item_site(distro, index_or_abbr)
    item = @mirrorz.items.find { |i| distro == i[:distro] }
    sites = item[:sites]
    index = sites.index { |site| site[:abbr] == index_or_abbr } || Integer(index_or_abbr)
    answer_with_message(sites[index][:items].map do |i|
      i.each_pair.map do |k, v|
        "#{t("mirrorz.info.urls.#{k}")}: #{v}"
      end.join("\n")
    end.join("\n\n"))
  rescue StandardError
    answer_with_message(t('not_found'))
  end

  def t(key)
    I18n.t(key, locals: @user.language_code)
  end

  def answer_with_message(text, parse_mode = nil)
    MessageSender.new(bot: @bot, chat: @message.chat, text: text, parse_mode: parse_mode).send
  end
end
