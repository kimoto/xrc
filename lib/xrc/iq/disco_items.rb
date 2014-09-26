module Xrc
  module IQ
    class DiscoItems < Base
      def initialize(element)
        super(element)

        rooms = []
        items = @element.elements["query"].children
        items.each do |channel|
          x = channel.elements["x"]
          last_active = x.elements["last_active"].text rescue nil
          rooms << {
            jid: channel.attribute("jid").value,
            name: channel.attribute("name").value,
            id: x.elements["id/text()"],
            topic: x.elements["topic/text()"],
            privacy: x.elements["privacy/text()"],
            owner: x.elements["owner/text()"],
            guest_url: x.elements["guest_url/text()"],
            num_participants: x.elements["num_participants/text()"],
            last_active: last_active
          }
        end
        @rooms = rooms.freeze
      end

      def room_jids
        @rooms.map{|room| room[:jid]}
      end

      def rooms
        @rooms
      end

      def to_hash
        {
          from: from,
          to: to,
          rooms: rooms()
        }
      end
    end
  end
end
