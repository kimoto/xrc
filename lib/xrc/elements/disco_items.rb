# Discovering Items
module Xrc
  module Elements
    class DiscoItems < REXML::Element
      def initialize(options={})
        super("iq")
        query = REXML::Element.new("query")
        query.add_namespace(Namespaces::DISCO_ITEMS)
        add_attributes("type" => "get")
        add_attributes("from" => options[:from])
        add_attributes("to" => options[:to])
        add(query)
      end
    end
  end
end
