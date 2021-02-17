require './lib/reply_markup_formatter'
require './lib/app_configurator'

class MessageSender
  def initialize(options)
    @bot = options[:bot]
    @text = options[:text]
    @chat = options[:chat]
    @answers = options[:answers]
    @parse_mode = options[:parse_mode]
  end

  def send
    if reply_markup
      @bot.api.send_message(chat_id: @chat.id, text: @text, parse_mode: @parse_mode, reply_markup: @reply_markup)
    else
      @bot.api.send_message(chat_id: @chat.id, text: @text, parse_mode: @parse_mode)
    end

    $logger.debug "sending '#{@text}' to #{@chat.username}"
  end

  private

  def reply_markup
    ReplyMarkupFormatter.new(@answers).markup if @answers
  end
end
