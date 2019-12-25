-- ubiquitousse

--- Ubiquitousse Game Framework.
-- Main module, which will try to load every other Ubiquitousse module when required and provide a few convenience functions.
--
-- Ubiquitousse may or may not be used in its totality. You can delete the modules directories you don't need and Ubiquitousse
-- should adapt accordingly. You can also simply copy the modules directories you need and use them directly, without using this
-- file at all.
-- However, some modules may provide more feature when other modules are available.
-- These dependencies are written at the top of every main module file.
--
-- Ubiquitousse's goal is to run everywhere with the least porting effort possible, so Ubiquitousse tries to only use features that
-- are almost sure to be available everywhere.
--
-- Some Ubiquitousse modules require functions that are not in the Lua standard library, and must therefore be implemented in a backend,
-- such as ubiquitousse.love. When required, modules will try to autodetect the engine it is running on, and load a correct backend.
--
-- Most Ubiquitousse module backends require a few things to be fully implemented:
-- * The backend needs to have access to some kind of main loop, or at least a function called very often (may or may not be the
--   same as the redraw screen callback).
-- * Some way of measuring time (preferably with millisecond-precision).
-- * Some kind of filesystem.
-- * Lua 5.1, 5.2, 5.3 or LuaJit.
-- * Other requirement for specific modules should be described in the module's documentation.
--
-- Units used in the API documentation:
-- * All distances are expressed in pixels (px)
-- * All durations are expressed in milliseconds (ms)
-- These units are only used to make writing documentation easier; you can use other units if you want, as long as you're consistent.
--
-- Style:
-- * tabs for indentation, spaces for esthetic whitespace (notably in comments)
-- * no globals
-- * UPPERCASE for constants (or maybe not).
-- * CamelCase for class names.
-- * lowerCamelCase is expected for everything else.
--
-- Implementation levels:
-- * backend: nothing defined in Ubiquitousse, must be implemented in backend
-- * mixed: partly implemented in Ubiquitousse but must be complemeted in backend.
-- * ubiquitousse: fully-working version in Ubiquitousse, may or may not be redefined in backend
-- The implementation level is indicated using the "@impl level" annotation.
--
-- For backend writers:
-- If a function defined here already contains some code, this means this code is mandatory and you must put/call
-- it in your implementation (except if the backend provides a more efficient implementation).
-- Also, a backend file shouldn't redefine the ubiquitousse table itself but only redefine the backend-dependant fields.
-- Lua 5.3: The API doesn't make the difference between numbers and integers, so convert to integers when needed.
--
-- For game writer:
-- Ubiquitousse works with Lua 5.1 to 5.3, including LuaJit, but doesn't provide any version checking or compatibility layer
-- between the different versions, so it's up to you to handle that in your game (or ignore the problem and sticks to your
-- main's backend Lua version).
--
-- Regarding the documentation: Ubiquitousse used LDoc/LuaDoc styled-comments, but since LDoc hates me and my code, the
-- generated result is complete garbage, so please read the documentation directly in the comments here until fix this.
-- Stuff you're interested in starts with triple - (e.g., "--- This functions saves the world").
--
-- @usage local ubiquitousse = require("ubiquitousse")

local p = ... -- require path
local ubiquitousse

ubiquitousse = {
	--- Ubiquitousse version.
	-- @impl ubiquitousse
	version = "0.0.1",

	--- Should be called each time the game loop is ran; will update every loaded Ubiquitousse module that needs it.
	-- @tparam number dt time since last call, in miliseconds
	-- @impl mixed
	update = function(dt)
		if ubiquitousse.timer then ubiquitousse.timer.update(dt) end
		if ubiquitousse.scene then ubiquitousse.scene.update(dt) end
		if ubiquitousse.input then ubiquitousse.input.update(dt) end
	end,

	--- Should be called each time the game expect a new frame to be drawn; will draw every loaded Ubiquitousse module that needs it
	-- The screen is expected to be cleared since last frame.
	-- @impl mixed
	draw = function()
		if ubiquitousse.scene then ubiquitousse.scene.draw() end
	end
}

-- We're going to require modules requiring Ubiquitousse, so to avoid stack overflows we already register the ubiquitousse package
package.loaded[p] = ubiquitousse

-- Require external submodules
for _, m in ipairs{"asset", "ecs", "input", "scene", "timer", "util"} do
	local s, t = pcall(require, p.."."..m)
	if s then
		ubiquitousse[m] = t
	end
end

-- Backend engine autodetect and load
if love then
	require(p..".backend.love")
elseif package.loaded["ctr"] then
	require(p..".backend.ctrulua")
elseif package.loaded["libretro"] then
	error("NYI")
end

return ubiquitousse
