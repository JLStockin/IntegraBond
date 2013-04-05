require 'faye'
Faye::WebSocket.load_adapter('thin')
faye = Faye::RackAdapter.new(mount: '/faye', timeout: 25)
run faye
