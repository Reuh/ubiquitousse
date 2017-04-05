-- ubiquitousse.draw
local uqt = require((...):match("^(.-ubiquitousse)%."))

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
--
-- Mostly plagiarized from the Löve API, with some parts from ctrµLua.
local draw
draw = {
	--- Initial game view paramters (some defaults).
	-- @impl ubiquitousse
	params = {
		title = "Ubiquitousse Game",
		width = 800,
		height = 600,
		resizable = false,
		resizeType = "auto"
	},

	--- Setup the intial game view parameters.
	-- If a parmeter is not set, a default value will be used.
	-- This function is expected to be only called once, before doing any drawing operation.
	-- @tparam table params the game parameters
	-- @usage -- Default values:
	-- ubiquitousse.init {
	--   title = "Ubiquitousse Game", -- usually window title
	--   width = 800, -- in px
	--   height = 600, -- in px
	--   resizable = false, -- can the game be resized?
	--   resizeType = "auto" -- how to act on resize: "none" to do nothing (0,0 will be top-left)
	--                                                "center" to autocenter (0,0 will be at windowWidth/2-gameWidth/2,windowHeight/2-gameHeight/2)
	--                                                "auto" to automatically resize to the window size (coordinate system won't change)
	-- }
	-- @impl mixed
	init = function(params)
		for k, v in pairs(params) do
			draw.params[k] = v
		end
		draw.width = params.width
		draw.height = params.height
	end,

	--- Return the number of frames per second.
	-- @treturn number the current FPS
	-- @impl backend
	fps = function() end,

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

	--- Draws a point.
	-- @tparam number x point x coordinate
	-- @tparam number y point y coordinate
	-- @tparam number ... other vertices to draw other points
	-- @impl backend
	point = function(x, y, ...) end,

	--- Sets the width.
	-- @tparam number width the line width
	-- @impl backend
	lineWidth = function(width) end,

	--- Draws a line.
	-- @tparam number x1 line start x coordinate
	-- @tparam number y1 line start y coordinate
	-- @tparam number x2 line end x coordinate
	-- @tparam number y2 line end y coordinate
	-- @tparam number ... other vertices to continue drawing a polyline
	-- @impl backend
	line = function(x1, y1, x2, y2, ...) end,

	--- Draws a filled polygon.
	-- @tparam number x1,y1,x2,y2... the vertices of the polygon
	-- @impl backend
	polygon = function(...) end,

	--- Draws a polygon outline.
	-- @tparam number x1,y1,x2,y2... the vertices of the polygon
	-- @impl backend
	linedPolygon = function(...) end,

	--- Draws a filled rectangle.
	-- @tparam number x rectangle top-left x coordinate
	-- @tparam number y rectangle top-left x coordinate
	-- @tparam number width rectangle width
	-- @tparam number height rectangle height
	-- @impl ubiquitousse
	rectangle = function(x, y, width, height)
		draw.polygon(x, y, x + width, y, x + width, y + height, x, y + height)
	end,

	--- Draws a rectangle outline.
	-- @tparam number x rectangle top-left x coordinate
	-- @tparam number y rectangle top-left x coordinate
	-- @tparam number width rectangle width
	-- @tparam number height rectangle height
	-- @impl ubiquitousse
	linedRectangle = function(x, y, width, height)
		draw.linedPolygon(x, y, x + width, y, x + width, y + height, x, y + height)
	end,

	--- Draws a filled circle.
	-- @tparam number x center x coordinate
	-- @tparam number y center x coordinate
	-- @tparam number radius circle radius
	-- @impl backend
	circle = function(x, y, radius) end,

	--- Draws a circle outline.
	-- @tparam number x center x coordinate
	-- @tparam number y center x coordinate
	-- @tparam number radius circle radius
	-- @impl backend
	linedCircle = function(x, y, radius) end,

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
	width = 800,

	--- The drawing area height, in pixels.
	-- @impl backend
	height = 600,

	-- TODO: doc & api
	push = function() end,
	pop = function() end,
	translate = function(x, y) end,
	rotate = function(angle) end,
	scale = function(sx, sy) end,
	font = function(filename) end,
	image = function(filename) end,
}

-- TODO: canvas stuff ; also make everything here actually be shortcut to draw to the game's framebuffer.
-- TODO: add software implementations of everything.
-- TODO: add function to draw a message (used eg for the error message when there is a version mismatch)

return draw
