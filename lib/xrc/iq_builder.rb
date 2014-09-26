module Xrc
  class IQBuilder < MessageBuilder
    # Builds a Message object from a REXML::Element.
    # @param [REXML::Element] element A message element
    # @return [Xrc::Messages::Base] An ancestor of Xrc::Messages::Base instance
    private
    def message_class
      case
      when has_disco_items?
        IQ::DiscoItems
      else
        Messages::Null
      end
    end

    def has_disco_items?
      if query_tag = @element.elements["query"]
        xmlns = query_tag.attribute('xmlns').value rescue nil
        return (xmlns =~ /disco#items\z/)
      else
        return false
      end
    end
  end
end
