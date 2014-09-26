# Xrc
XMPP Ruby Client.

## Usage
```ruby
# Loads all classes & modules defined in this library.
require "xrc"

# Constructs a new Client class to connect to a XMPP server.
client = Xrc::Client.new(
  jid: "foo@example.com",      # required
  nickname: "bot"              # optional
  password: "xxx",             # optional
  hosts: [ "example.com" ],    # optional, automatically determined from JID in absence
  port: 5222,                  # optional, default: 5222
  room_jid: "bar@example.com", # optional, you can pass comma-separated multi room JIDs
  muc_domain: "example.com",   # optional
)

client.on_connect do
  client.discovering_rooms
end

client.on_discovered_rooms do |resp|
  jids = resp.room_jids
  client.join(jids)
  puts "joined rooms!: #{jids}"
end

# Responds to "ping" and returns "pong".
client.on_private_message do |message|
  if message.body == "ping"
    client.reply(body: "pong", to: message)
  end
end

# Responds to "Thank you" and returns "You're welcome".
client.on_room_message do |message|
  if message.body == "Thank you"
    client.reply(body: "You're welcome", to: message)
  end
end

# Connects to a XMPP server and waits for new messages.
client.connect
```
