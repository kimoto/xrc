module Xrc
  class Client
    DEFAULT_PORT = 5222

    BIND_NAMESPACE = "urn:ietf:params:xml:ns:xmpp-bind"

    ROSTER_NAMESPACE = "jabber:iq:roster"

    SASL_NAMESPACE = "urn:ietf:params:xml:ns:xmpp-sasl"

    SESSION_NAMESPACE = "urn:ietf:params:xml:ns:xmpp-session"

    TLS_NAMESPACE = "urn:ietf:params:xml:ns:xmpp-tls"

    attr_accessor :users

    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    def run
      connect
      start
      wait
    end

    def receive(element)
      case
      when element.attribute("id") && has_reply_callbacks_to?(element.attribute("id").value)
        on_replied(element)
      when element.prefix == "stream" && element.name == "features"
        on_features_received(element)
      when element.name == "proceed" && element.namespace == TLS_NAMESPACE
        on_tls_proceeded(element)
      when element.name == "success" && element.namespace == SASL_NAMESPACE
        on_authentication_succeeded(element)
      when element.name == "failure" && element.namespace == SASL_NAMESPACE
        on_authentication_failed(element)
      end
    end

    log :receive do |element|
      "Received:\n" + "#{REXML::Formatters::Pretty.new(2).write(element, '')}".indent(2)
    end

    private

    def jid
      @jid ||= Jid.new(options[:jid])
    end

    def password
      options[:password]
    end

    def nickname
      options[:nickname]
    end

    def port
      options[:port] || DEFAULT_PORT
    end

    def room_jid
      Jid.new("#{options[:room_jid]}") if options[:room_jid]
    end

    def on_bound(element)
      @jid = Jid.new(element.elements["/bind/jid/text()"].value)
      establish_session
      require_roster
    end

    def on_replied(element)
      id = element.attribute("id").value
      callback = reply_callbacks.delete(id)
      callback.call(element)
    end

    def on_features_received(element)
      element.each do |feature|
        case
        when feature.name == "bind" && feature.namespace == BIND_NAMESPACE
          bind
        when feature.name == "starttls" && feature.namespace == TLS_NAMESPACE
          start_tls
        when feature.name == "mechanisms" && feature.namespace == SASL_NAMESPACE
          on_mechanisms_received(feature)
        else
          features[feature.name] = feature.namespace
        end
      end
    end

    def on_authentication_succeeded(element)
      start
    end

    def on_authentication_failed(element)
      raise NotImplementedError
    end

    def on_tls_proceeded(element)
      change_socket
    end

    def on_mechanisms_received(element)
      element.each_element("mechanism") do |mechanism|
        mechanisms << mechanism.text
      end
      authenticate if password
    end

    def on_roster_received(element)
      self.users = element.elements.collect("query/item") do |item|
        OpenStruct.new(
          jid: item.attribute("jid").value,
          mention_name: item.attribute("mention_name").value,
          name: item.attribute("name").value,
        )
      end
      attend
      join if room_jid
    end

    def authenticate
      case
      when mechanisms.include?("PLAIN")
        auth = Elements::Auth.new(jid: jid, password: password)
        post(auth)
      else
        raise NotImplementedError
      end
    end

    def connect
      socket
    end

    log :connect do
      "Connecting to #{domain}:#{port}"
    end

    def start_tls
      post(Elements::Starttls.new)
    end

    def change_socket
      @socket = tsl_connector.connect
      start
      regenerate_parser
      wait
    end

    def wait
      parser.parse
    end

    def parser
      @parser ||= generate_parser
    end

    def generate_parser
      Parser.new(socket, client: self)
    end

    def regenerate_parser
      @parser = generate_parser
    end

    def socket
      @socket ||= connector.connect
    end

    def features
      @features ||= {}
    end

    def mechanisms
      @mechanisms ||= []
    end

    def connector
      Connector.new(domain: domain, port: port)
    end

    def tsl_connector
      TslConnector.new(socket: socket)
    end

    def domain
      jid.domain
    end

    def start
      post(Elements::Stream.new(domain))
    end

    def post(element)
      socket << element.to_s
    end

    log :post do |element|
      "Posting:\n" + element.to_s.indent(2)
    end

    def post_with_id(element, &block)
      id = generate_id
      element.add_attributes("id" => id)
      if block
        reply_callbacks[id] = block
      end
      post(element)
    end

    def bind
      post_with_id(Elements::Bind.new(resource: jid.resource), &method(:on_bound))
    end

    def reply_callbacks
      @reply_callbacks ||= {}
    end

    def has_reply_callbacks_to?(id)
      reply_callbacks.has_key?(id)
    end

    # See RFC1750 for Randomness Recommendations for Security
    def generate_id
      SecureRandom.hex(8)
    end

    def establish_session
      post_with_id(Elements::Session.new)
    end

    def require_roster
      post_with_id(Elements::Roster.new, &method(:on_roster_received))
    end

    def users_indexed_by_jid
      @users_indexed_by_jid ||= users.index_by(&:jid)
    end

    def attend
      post(Elements::Presence.new)
    end

    def join
      post(Elements::Join.new(from: jid.strip, to: "#{room_jid}/#{nickname}"))
    end
  end
end
