-- ubiquitousse.event
local uqt = require((...):match("^(.-ubiquitousse)%."))
local input = uqt.input
local time = uqt.time
local scene = uqt.scene

--- The events: callback functions that will be called when something interesting occurs.
-- Theses are expected to be redefined in the game.
-- For backend writers: if they already contain code, then this code has to be called on each call, even
-- if the user manually redefines them.
-- @usage -- in the game's code
-- ubiquitousse.event.draw = function()
--   ubiquitousse.draw.text(5, 5, "Hello world")
-- end
return {
	--- Called each time the game loop is ran. Don't draw here.
	-- @tparam number dt time since last call, in miliseconds
	-- @impl mixed
	update = function(dt)
		if input then input.update(dt) end
		if time then time.update(dt) end
		if scene then scene.update(dt) end
	end,

	--- Called each time the game expect a new frame to be drawn.
	-- The screen is expected to be cleared since last frame.
	-- @impl backend
	draw = function()
		if scene then scene.draw() end
	end
}
