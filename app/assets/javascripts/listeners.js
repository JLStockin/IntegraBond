// Partials to:
// Register any page presented to a signed-in user as a recipient
// of flash messages, which may come from the model layer
//
// Register any page displaying transaction data to receive updates 
//
// server, flash_channel and update_channel are defined in
// _setup_listeners.html.erb 
//
var server = "";
var flash_channel = "";
var update_channel = "";

var pushListener = {
	// TODO: update flash control via ajax
	onFlashCallback : function(msg) {
		window.location = window.location;
		alert("flash: " + msg);
	},
	onUpdateCallback : function(msg) {
		window.location = window.location;
		alert("update: " + msg);
	},
	registerFlashListener : function(server, channel) {
		var client = new Faye.Client(server);
		client.subscribe(channel, this.onFlashCallback.bind(this));
	},
	registerUpdateListener : function(server, channel) {
		var client = new Faye.Client(server);
		client.subscribe(channel, this.onFlashCallback.bind(this));
	}
};
