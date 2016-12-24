-- ubiquitousse

--- Ubiquitousse Game Engine.
-- Main module, containing the main things.
-- The API exposed here is the Ubiquitousse API.
-- It is as the name does not imply anymore abstract, and must be implemented in a backend, such as ubiquitousse.love.
-- When required, this file will try to autodetect the engine it is running on, and load a correct backend.
--
-- Ubiquitousse may or may not be used as a full game engine. You can delete the modules files you don't need and Ubiquitousse
-- should adapt accordingly.
--
-- For backend writers:
-- If a function defined here already contains some code, this means this code is mandatory and you must put/call
-- it in your implementation.
-- Also, a backend file shouldn't redefine the ubiquitousse table itself but only redefine the backend-dependant fields.
-- The API doesn't make the difference between numbers and integers, so convert to integers when needed.
--
-- Ubiquitousse's goal is to run everywhere with the least porting effort possible.
-- To achieve this, the engine needs to stay simple, and only provide features that are almost sure to be
-- available everywhere, so writing a backend should be straighforward.
-- However, Ubiquitousse still make some small assumptions about the engine:
-- * The engine has some kind of main loop, or at least a function called very often (may or may not be the
--   same as the redraw screen callback).
-- * 32bit color depth.
--
-- Regarding data formats, Ubiquitousse reference implemtations expect and recommend:
-- * For images, PNG support is expected.
-- * For audio files, OGG Vorbis support is expected.
-- * For fonts, TTF support is expected.
-- Theses formats are respected for the reference implementations, but Ubiquitousse may provide a script to
-- automatically convert data formats from a project at some point.
--
-- Units used in the API:
-- * All distances are expressed in pixels (px)
-- * All durations are expressed in milliseconds (ms)
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
-- * mixed: partly implemented in Ubiquitousse but must be complemeted in backend
-- * ubiquitousse: fully-working version in Ubiquitousse, may or may not be redefined in backend
-- The implementation level is indicated using the "@impl level" annotation.
--
-- @usage local ubiquitousse = require("ubiquitousse")

local p = ... -- require path
local ubiquitousse

ubiquitousse = {
	--- Ubiquitousse version.
	-- @impl ubiquitousse
	version = "0.0.1",

	--- Backend name.
	-- For consistency, only use lowercase letters [a-z] (no special char)
	-- @impl backend
	backend = "unknown"
}

-- We're going to require modules requiring Ubiquitousse, so to avoid stack overflows we already register the ubiquitousse package
package.loaded[p] = ubiquitousse

-- Require external submodules
for _, m in ipairs({"time", "draw", "audio", "input", "scene", "event"}) do
	local s, t = pcall(require, p.."."..m)
	if s then ubiquitousse[m] = t end
end

-- Backend engine autodetect and load
if love then
	require(p..".backend.love")
elseif package.loaded["ctr"] then
	require(p..".backend.ctrulua")
end

return ubiquitousse
