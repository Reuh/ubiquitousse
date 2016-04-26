-- abstract.event
local abstract = require((...):match("^(.-abstract)%."))
local input = abstract.input
local time = abstract.time
local scene = abstract.scene

--- The events: callback functions that will be called when something interesting occurs.
-- Theses are expected to be redefined in the game.
-- For backend writers: if they already contain code, then this code has to be called on each call.
-- @usage -- in the game's code
-- abstract.event.draw = function()
--   abstract.draw.text(5, 5, "Hello world")
-- end
return {
	--- Called each time the game loop is ran. Don't draw here.
	-- @tparam number dt time since last call, in seconds
	-- @impl mixed
	update = function(dt)
		input.update(dt)
		time.update(dt)
		scene.update(dt)
	end,
	
	--- Called each time the game expect a new frame to be drawn.
	-- The screen is expected to be cleared since last frame.
	-- @impl backend
	draw = function()
		scene.draw()
	end
}
