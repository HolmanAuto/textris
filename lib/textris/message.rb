module Textris
  class Message
    attr_reader :content, :from_name, :from_phone, :to, :texter, :action

    def initialize(options = {})
      @to      = parse_to      options[:to]
      @content = parse_content options[:content]

      if options.has_key?(:from)
        @from_name, @from_phone = parse_from options[:from]
      else
        @from_name  = options[:from_name]
        @from_phone = options[:from_phone]
      end

      unless @content.present?
        raise(ArgumentError, "Content must be provided")
      end

      unless @to.present?
        raise(ArgumentError, "Recipients must be provided and E.164 compilant")
      end

      @texter = options[:texter]
      @action = options[:action]
    end

    def deliver
      deliveries = ::Textris::Delivery.get
      deliveries.each do |delivery|
        delivery.send_message_to_all(self)
      end

      self
    end

    private

    def parse_from(from)
      if from.blank?
        nil
      elsif (matches = from.match(/(.*)\<(.*)\>\s*$/).to_a).size == 3 &&
          Phony.plausible?(matches[2])
        [matches[1].strip, Phony.normalize(matches[2])]
      elsif Phony.plausible?(from)
        [nil, Phony.normalize(from)]
      else
        [from.strip, nil]
      end
    end

    def parse_to(to)
      to = [*to]
      to = to.select { |phone| Phony.plausible?(phone) }
      to = to.map    { |phone| Phony.normalize(phone) }

      to
    end

    def parse_content(content)
      content = content.gsub(/\s{1,}/, ' ')
      content = content.strip

      content
    end
  end
end
