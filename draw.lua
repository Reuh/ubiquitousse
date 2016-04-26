-- abstract.draw
local abstract = require((...):match("^(.-abstract)%."))

--- The drawing functions: everything that affect the display/window.
-- The coordinate system used is:
-- 
--  (0,0) +---> (x)
--        |
--        |
--        v (y)
--
-- x and y values can be float, so make sure to perform math.floor if your engine only support
-- integer coordinates.
return {
	--- Sets the drawing color
	-- @tparam number r the red component (0-255)
	-- @tparam number g the green component (0-255)
	-- @tparam number b the blue component (0-255)
	-- @tparam[opt=255] number a the alpha (opacity) component (0-255)
	-- @impl backend
	color = function(r, g, b, a) end,

	--- Draws some text.
	-- @tparam number x x top-left coordinate of the text
	-- @tparam number y y top-left coordinate of the text
	-- @tparam string text the text to draw. UTF-8 format, convert if needed.
	-- @impl backend
	text = function(x, y, text) end,

	--- Draws a line.
	-- @tparam number x1 line start x coordinate
	-- @tparam number y1 line start y coordinate
	-- @tparam number x2 line end x coordinate
	-- @tparam number y2 line end y coordinate
	-- @impl backend
	line = function(x1, y1, x2, y2) end,

	--- Draws a filled rectangle
	-- @tparam number x rectangle top-left x coordinate
	-- @tparam number y rectangle top-left x coordinate
	-- @tparam number width rectangle width
	-- @tparam number height rectangle height
	-- @impl backend
	rectangle = function(x, y, width, height) end,

	--- Enables the scissor test.
	-- When enabled, every pixel drawn outside of the scissor rectangle is discarded.
	-- When called withou arguments, it disables the scissor test.
	-- @tparam number x rectangle top-left x coordinate
	-- @tparam number y rectangle top-left x coordinate
	-- @tparam number width rectangle width
	-- @tparam number height rectangle height
	-- @impl backend
	scissor = function(x, y, width, height) end,

	--- The drawing area width, in pixels.
	-- @impl backend
	width = abstract.params.width,

	--- The drawing area height, in pixels.
	-- @impl backend
	height = abstract.params.height,

	-- TODO: doc & api
	push = function() end,
	pop = function() end,
	polygon = function(...) end,
	circle = function(x, y, radius) end,
	translate = function(x, y) end,
	font = function(filename) end,
	image = function(filename) end,
}
