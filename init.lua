-- abstract

--- Abstract Engine.
-- Main module, containing the abstract things.
-- The API exposed here is the Abstract API.
-- It is as the name imply abstract, and must be implemented in a backend, such as abstract.love.
-- When required, this file will try to autodetect the engine it is running on, and load a correct backend.
--
-- For backend writers:
-- If a function defined here already contains some code, this means this code is mandatory and you must put/call
-- it in your implementation.
-- Also, a backend file shouldn't redefine the abstract table itself but only redefine the backend-dependant fields.
-- The API doesn't make the difference between numbers and integers, so convert to integers when needed.
--
-- Abstract's goal is to run everywhere with the least porting effort possible.
-- To achieve this, the engine needs to stay simple, and only provide features that are almost sure to be
-- available everywhere, so writing a backend should be straighforward.
-- However, Abstract still make some small assumptions about the engine:
-- * The engine has some kind of main loop, or at least a function called very often (may or may not be the
--   same as the redraw screen callback).
-- * 32bit color depth.
--
-- Regarding data formats, Abstract reference implemtations expect and recommend:
-- * For images, PNG support is expected.
-- * For audio files, OGG Vorbis support is expected.
-- * For fonts, TTF support is expected.
-- Theses formats are respected for the reference implementations, but Abstract may provide a script to
-- automatically convert data formats from a project at some point.
--
-- Style:
-- * tabs for indentation, spaces for esthetic whitespace (notably in comments)
-- * no globals
-- * UPPERCASE for constants (or maybe not).
-- * CamelCase for class names.
-- * lowerCamelCase is expected for everything else.
--
-- Implementation levels:
-- * backend: nothing defined in abstract, must be implemented in backend
-- * mixed: partly implemented in abstract but must be complemeted in backend
-- * abstract: fully-working version in abstract, may or may not be redefined in backend
-- The implementation level is indicated using the "@impl level" annotation.
--
-- @usage local abstract = require("abstract")

local p = ... -- require path
local abstract

abstract = {
	--- Abstract version.
	-- @impl abstract
	version = "0.0.1",

	--- Backend name.
	-- For consistency, only use lowercase letters [a-z] (no special char)
	-- @impl backend
	backend = "unknown",

	--- General game paramters (some defaults).
	-- @impl abstract
	params = {
		title = "Abstract Engine",
		width = 800,
		height = 600,
		resizable = false,
		resizeType = "auto"
	},

	--- Setup general game parameters.
	-- If a parmeter is not set, a default value will be used.
	-- This function is expected to be only called once, before doing any drawing operation.
	-- @tparam table params the game parameters
	-- @usage -- Default values:
	-- abstract.setup {
	--   title = "Abstract Engine", -- usually window title
	--   width = 800, -- in px
	--   height = 600, -- in px
	--   resizable = false, -- can the game be resized?
	--   resizeType = "auto" -- how to act on resize: "none" to do nothing (0,0 will be top-left)
	--                                                "center" to autocenter (0,0 will be at windowWidth/2-gameWidth/2,windowHeight/2-gameHeight/2)
	--                                                "auto" to automatically resize to the window size (coordinate system won't change)
	-- }
	-- @impl mixed
	setup = function(params)
		for k, v in pairs(params) do
			abstract.params[k] = v
		end
		abstract.draw.width = params.width
		abstract.draw.height = params.height
	end,

	--- Frames per second (the backend should update this value).
	-- @impl backend
	fps = 60,

	--- Time since last frame (seconds)
	-- @impl backend
	dt = 0
}

-- We're going to require modules requiring abstract, so to avoid stack overflows we already register the abstract package
package.loaded[p] = abstract

-- External submodules
abstract.time = require(p..".time")
abstract.draw = require(p..".draw")
abstract.audio = require(p..".audio")
abstract.input = require(p..".input")
abstract.scene = require(p..".scene")
abstract.event = require(p..".event")

-- Backend engine autodetect and load
if love then
	require(p..".backend.love")
elseif package.loaded["ctr"] then
	require(p..".backend.ctrulua")
end

return abstract
