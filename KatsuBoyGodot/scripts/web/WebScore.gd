class_name WebScore
extends RefCounted

## Reports the player's progress up to the web page hosting this build, which
## forwards it to the kamimart.com high-score board.
##
## Does nothing outside the browser export, and nothing harmful when the build
## is opened on its own rather than embedded in a page - the parent window is
## then this window, and the message just goes nowhere.
##
## Katsu Boy has no name-entry screen, so no name is sent. The hosting page asks
## for one the first time and remembers it.


## Seconds of play in this session. Katsu Boy keeps no playtime of its own, and
## the engine clock starting at launch is close enough for a board column.
static func session_seconds() -> int:
	return int(Time.get_ticks_msec() / 1000.0)


static func post_progress(level: int, coins: int) -> void:
	if not OS.has_feature("web"):
		return
	var payload := JSON.stringify({
		"type": "kamimart.score",
		"game": "katsuboy",
		# The board ranks Katsu Boy by level, so that is the headline number.
		"score": level,
		"level": level,
		"coins": coins,
		"runSeconds": session_seconds(),
	})
	# This build is served from the same origin as the page that frames it, so
	# the page's own origin is a valid target and keeps progress off any other
	# site that might embed the game.
	JavaScriptBridge.eval(
		"try { window.parent.postMessage(%s, window.location.origin); } catch (e) {}" % payload,
		true
	)
