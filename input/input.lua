--- ubiquitousse.input
-- Depends on a backend.
-- Optional dependencies: ubiquitousse.signal (to bind to update signal in signal.event)
local loaded, signal = pcall(require, (...):match("^(.-)input").."signal")
if not loaded then signal = nil end

-- TODO: some key selection helper? Will be backend-implemented, to account for all the possible input methods.
-- TODO: some way to list all possible input / outputs, or make the *inUse make some separation between inputs indiscutitably in use and those who are incertain.
-- TODO: outputs! (rumble, lights, I don't know)
-- TODO: other, optional, default/generic inputs, and a way to know if they are binded.
-- TODO: multiplayer input helpers? something like getting the same input for different players, or default inputs for different players

-- FIXME https://love2d.org/forums/viewtopic.php?p=241434#p241434

local button_mt
local axis_mt
local pointer_mt

--- Input stuff
-- Inspired by Tactile by Andrew Minnich (https://github.com/tesselode/tactile), under the MIT license.
-- Ubiquitousse considers two basic input methods, called buttons (binary input) and axes (analog input).
local input
input = {
	--- Used to store inputs which were updated this frame
	-- { Input: true, ... }
	-- This table is for internal use and shouldn't be used from an external script.
	updated = {},

	dt = 0,

	---------------------------------
	--- Detectors (input sources) ---
	---------------------------------

	-- Buttons detectors --
	-- A button detector is a function which returns true (pressed) or false (unpressed).
	-- All buttons are identified using an identifier string, which depends on the backend. The presence of eg., a mouse or keyboard is not assumed.
	-- Some identifier strings conventions: (not used internally by Ubiquitousse, but it's nice to have some consistency between backends)
	-- They should be in the format "source1.source2.[...].button", for example "keyboard.up" or "gamepad.button.1.a" for the A-button of the first gamepad.
	-- If the button is actually an axis (ie, the button is pressed if the axis value passes a certain threshold), the threshold should be in the end of the
	-- identifier, preceded by a % : for example "gamepad.axis.1.leftx%-0.5" should return true when the left-stick of the first gamepad is moved to the right
	-- by more of 50%. The negative threshold value means that the button will be pressed only when the axis has a negative value (in the example, it won't be
	-- pressed when the axis is moved to the right).
	-- Buttons can also be defined by a list of buttons (string or functions), in which case the button will be considered down if all the buttons are down.

	--- Makes a new button detector from a identifier string.
	-- The function may error if the identifier is incorrect.
	-- @tparam string button identifier, depends on the platform Ubiquitousse is running on
	-- @treturn the new button detector
	-- @require love
	basicButtonDetector = function(str) end,

	--- Make a new button detector from a detector function, string, or list of buttons.
	-- @tparam string, function button identifier
	buttonDetector = function(obj)
		if type(obj) == "function" then
			return obj
		elseif type(obj) == "string" then
			return input.basicButtonDetector(obj)
		elseif type(obj) == "table" then
			local l = {}
			for _, b in ipairs(obj) do
				table.insert(l, input.buttonDetector(b))
			end
			return function()
				for _, b in ipairs(l) do
					if not b() then
						return false
					end
				end
				return true
			end
		end
		error(("Not a valid button detector: %s"):format(obj))
	end,

	-- Axis detectors --
	-- Similar to buttons detectors, but returns a number between -1 and 1.
	-- Threshold value can be used similarly with %.
	-- Axis detectors can also be defined by two buttons: if the 1rst button is pressed, value will be -1, if the 2nd is pressed it will be 1
	-- and if none or the both are pressed, the value will be 0. This kind of axis identifier is a table {"button1", "button2"}.
	-- Axis detectors may also optionally return after the number between -1 and 1 the raw value and max value. The raw value is between -max and +max.

	--- Makes a new axis detector from a identifier string.
	-- The function may error if the identifier is incorrect.
	-- @tparam string axis identifier, depends on the platform Ubiquitousse is running on
	-- @treturn the new axis detector
	-- @require love
	basicAxisDetector = function(str) end,

	--- Make a new axis detector from a detector function, string, or a couple of buttons.
	-- @tparam string, function or table axis identifier
	axisDetector = function(obj)
		if type(obj) == "function" then
			return obj
		elseif type(obj) == "string" then
			return input.basicAxisDetector(obj)
		elseif type(obj) == "table" then
			local b1, b2 = input.buttonDetector(obj[1]), input.buttonDetector(obj[2])
			return function()
				local d1, d2 = b1(), b2()
				if d1 and d2 then return 0
				elseif d1 then return -1
				elseif d2 then return 1
				else return 0 end
			end
		end
		error(("Not a valid axis detector: %s"):format(obj))
	end,

	------------------------------
	--- Input detection helpers --
	------------------------------
	-- TODO: make this better

	--- Returns a list of the buttons currently in use, identified by their string button identifier.
	-- This may also returns "axis threshold" buttons if an axis passes the threshold.
	-- @tparam[opt=0.5] number threshold the threshold to detect axes as button
	-- @treturn string,... buttons identifiers list
	-- @require love
	buttonUsed = function(threshold) end,

	--- Returns a list of the axes currently in use, identified by their string axis identifier
	-- @tparam[opt=0.5] number threshold the threshold to detect axes
	-- @treturn string,... axes identifiers list
	-- @require love
	axisUsed = function(threshold) end,

	--- Returns a nice name for the button identifier.
	-- Can be locale-depedant and stuff, it's only for display.
	-- May returns the raw identifier if you're lazy.
	-- @tparam string... button identifier string(s)
	-- @treturn string... the displayable names
	-- @require love
	buttonName = function(...) end,

	--- Returns a nice name for the axis identifier.
	-- Can be locale-depedant and stuff, it's only for display.
	-- May returns the raw identifier if you're lazy.
	-- @tparam string... axis identifier string(s)
	-- @treturn string... the displayable names
	-- @require love
	axisName = function(...) end,

	-------------------
	--- Other stuff ---
	-------------------

	--- Some default inputs.
	-- The backend should bind detectors to thoses inputs (don't recreate them).
	-- These are used to provide some common input default detectors to allow to start a game quickly on
	-- any platform without having to configure the keys.
	-- If some key function in your game match one of theses defaults, using it instead of creating a new
	-- input would be a good idea.
	-- @require love
	default = {
		pointer = nil, -- Pointer: used to move and select. Example binds: arrow keys, WASD, stick.
		confirm = nil, -- Button: used to confirm something. Example binds: Enter, A button.
		cancel = nil -- Button: used to cancel something. Example binds: Escape, B button.
	},

	--- Get draw area dimensions.
	-- Used for pointers.
	-- @require love
	getDrawWidth = function() return 1 end,
	getDrawHeight = function() return 1 end,

	--- Update all the Inputs.
	-- Should be called at every game update. If ubiquitousse.signal is available, will be bound to the "update" signal in signal.event.
	-- The backend can hook into this function to to its input-related updates.
	-- @tparam numder dt the delta-time
	update = function(newDt)
		input.dt = newDt
		input.updated = {}
	end

	--- If you use LÖVE, note that in order to provide every feature (especially key detection), several callbacks functions will
	-- need to be called on LÖVE events. See backend/love.lua.
	-- If ubiquitousse.signal is available, these callbacks will be bound to signals in signal.event (with the same name as the LÖVE
	-- callbacks, minux the "love.").
}

package.loaded[...] = input
button_mt = require((...):gsub("input$", "button"))
axis_mt = require((...):gsub("input$", "axis"))
pointer_mt = require((...):gsub("input$", "pointer"))

-- Constructors
input.button = button_mt._new
input.axis = axis_mt._new
input.pointer = pointer_mt._new

-- Create default inputs
input.default.pointer = input.pointer()
input.default.confirm = input.button()
input.default.cancel = input.button()

-- Bind signals
if signal then
	signal.event:bind("update", input.update)
end

require((...):gsub("input$", "love"))

return input
