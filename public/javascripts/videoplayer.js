// videoplayer.js
//
// Plays video splash screen first time user visits site (or again if cookie is lost)
//

var player = _V_("splash_video", { "example_option":true } );
showPlayer(false);
player.ready(readyCallback);

// Called when player finishes initializing itself 

function readyCallback()
{
	var player = this;

	player.volume(0);
	player.addEvent("ended", endedCallback);
	player.addEvent("error", errorCallback);
	showPlayer(true);
	player.play();
}


// Called when video finishes

function endedCallback()
{
	showPlayer(false);
	player.cancelFullScreen();
}

// Available for use later

function errorCallback()
{
}


// Utility to set player's visibility
function showPlayer(state)
{
	var id = getPlayerId();

	if (state == true)
	{
		id.style.visibility = "visible";
	}
	else
	{
		if (state == false) {
			id.style.visibility = "hidden";
		}
		else
		{
			alert("got bad value: " + value);
		}
	}
}

// Utility to get player's DOM id

function getPlayerId()
{
	var id = document.getElementById("splash_video");
	return id;
}

