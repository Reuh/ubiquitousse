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

local input
local sqrt = math.sqrt
local unpack = table.unpack or unpack
local dt = 0

--- Used to store inputs which were updated this frame
-- { Input: true, ... }
-- This table is for internal use and shouldn't be used from an external script.
local updated = {}

--- ButtonInput methods
-- @impl ubiquitousse
local button_mt = {
	--- Returns a new ButtonInput with the same properties.
	-- @treturn ButtonInput the cloned object
	clone = function(self)
		return input.button(unpack(self.detectors))
	end,

	--- Bind new ButtonDetector(s) to this input.
	-- @tparam ButtonDetectors ... buttons detectors or buttons identifiers to add
	-- @treturn ButtonInput this ButtonInput object
	bind = function(self, ...)
		for _, d in ipairs({...}) do
			table.insert(self.detectors, input.buttonDetector(d))
		end
		return self
	end,
	--- Unbind ButtonDetector(s).
	-- @tparam ButtonDetectors ... buttons detectors or buttons identifiers to remove
	-- @treturn ButtonInput this ButtonInput object
	unbind = function(self, ...)
		for _, d in ipairs({...}) do
			for i=#self.detectors, 1, -1 do
				if self.detectors[i] == d then
					table.remove(self.detectors, i)
					break
				end
			end
		end
		return self
	end,
	--- Unbind all ButtonDetector(s).
	-- @treturn ButtonInput this ButtonInput object
	clear = function(self)
		self.detectors = {}
		return self
	end,

	--- Hijacks the input.
	-- This function returns a new input object which mirrors the current object, except it will hijack every new input.
	-- This means any new button press/down/release will only be visible to the new object; the button will always appear unpressed for the initial object.
	-- This is useful for contextual input, for example if you want to display a menu without pausing the game: the menu
	-- can hijack relevant inputs while it is open, so they don't trigger any action in the rest of the game.
	-- An input can be hijacked several times; the one which hijacked it last will be the active one.
	-- @treturn ButtonInput the new input object which is hijacking the input
	hijack = function(self)
		local hijacked = setmetatable({}, { __index = self, __newindex = self })
		table.insert(self.hijackStack, hijacked)
		self.hijacking = hijacked
		return hijacked
	end,
	--- Release the input that was hijacked by this object.
	-- Input will be given back to the previous object.
	-- @treturn ButtonInput this ButtonInput object
	free = function(self)
		local hijackStack = self.hijackStack
		for i, v in ipairs(hijackStack) do
			if v == self then
				table.remove(hijackStack, i)
				self.hijacking = hijackStack[#hijackStack]
				return self
			end
		end
		error("This object is currently not hijacking this input")
	end,

	--- Returns true if the input was just pressed.
	-- @treturn boolean true if the input was pressed, false otherwise
	pressed = function(self)
		if self.hijacking == self then
			self:update()
			return self.state == "pressed"
		else
			return false
		end
	end,
	--- Returns true if the input was just released.
	-- @treturn boolean true if the input was released, false otherwise
	released = function(self)
		if self.hijacking == self then
			self:update()
			return self.state == "released"
		else
			return false
		end
	end,
	--- Returns true if the input is down.
	-- @treturn boolean true if the input is currently down, false otherwise
	down = function(self)
		if self.hijacking == self then
			self:update()
			local state = self.state
			return state == "down" or state == "pressed"
		else
			return false
		end
	end,
	--- Returns true if the input is up.
	-- @treturn boolean true if the input is currently up, false otherwise
	up = function(self)
		return not self:down()
	end,

	--- Update button state.
	-- Automatically called, don't call unless you know what you're doing.
	-- @impl ubiquitousse
	update = function(self)
		if not updated[self] then
			local down = false
			for _, d in ipairs(self.detectors) do
				if d() then
					down = true
					break
				end
			end
			local state = self.state
			if down then
				if state == "none" or state == "released" then
					self.state = "pressed"
				else
					self.state = "down"
				end
			else
				if state == "down" or state == "pressed" then
					self.state = "released"
				else
					self.state = "none"
				end
			end
			updated[self] = true
		end
	end
}
button_mt.__index = button_mt

--- AxisInput methods
-- @impl ubiquitousse
local axis_mt = {
	--- Returns a new AxisInput with the same properties.
	-- @treturn AxisInput the cloned object
	clone = function(self)
		return input.axis(unpack(self.detectors))
		       :threshold(self.threshold)
	end,

	--- Bind new AxisDetector(s) to this input.
	-- @tparam AxisDetectors ... axis detectors or axis identifiers to add
	-- @treturn AxisInput this AxisInput object
	bind = function(self, ...)
		for _,d in ipairs({...}) do
			table.insert(self.detectors, input.axisDetector(d))
		end
		return self
	end,
	--- Unbind AxisDetector(s).
	-- @tparam AxisDetectors ... axis detectors or axis identifiers to remove
	-- @treturn AxisInput this AxisInput object
	unbind = button_mt.unbind,
	--- Unbind all AxisDetector(s).
	-- @treturn AxisInput this AxisInput object
	clear = button_mt.clear,

	--- Hijacks the input.
	-- This function returns a new input object which mirrors the current object, except it will hijack every new input.
	-- This means any value change will only be visible to the new object; the axis will always appear to be at 0 for the initial object.
	-- An input can be hijacked several times; the one which hijacked it last will be the active one.
	-- @treturn AxisInput the new input object which is hijacking the input
	hijack = function(self)
		local hijacked
		hijacked = setmetatable({
			positive = input.button(function() return hijacked:value() > self.triggeringThreshold end),
			negative = input.button(function() return hijacked:value() < self.triggeringThreshold end)
		}, { __index = self, __newindex = self })
		table.insert(self.hijackStack, hijacked)
		self.hijacking = hijacked
		return hijacked
	end,
	--- Release the input that was hijacked by this object.
	-- Input will be given back to the previous object.
	-- @treturn AxisInput this AxisInput object
	free = button_mt.free,

	--- Sets the default detection threshold (deadzone).
	-- 0 by default.
	-- @tparam number new the new detection threshold
	-- @treturn AxisInput this AxisInput object
	threshold = function(self, new)
		self.threshold = tonumber(new)
		return self
	end,

	--- Returns the value of the input (between -1 and 1).
	-- @tparam[opt=default threshold] number threshold value to use
	-- @treturn number the input value
	value = function(self, curThreshold)
		if self.hijacking == self then
			self:update()
			local val = self.val
			return math.abs(val) > math.abs(curThreshold or self.threshold) and val or 0
		else
			return 0
		end
	end,
	--- Returns the change in value of the input since last update (between -2 and 2).
	-- @treturn number the value delta
	delta = function(self)
		if self.hijacking == self then
			self:update()
			return self.dval
		else
			return 0
		end
	end,
	--- Returns the raw value of the input (between -max and +max).
	-- @tparam[opt=default threshold*max] number raw threshold value to use
	-- @treturn number the input raw value
	raw = function(self, rawThreshold)
		if self.hijacking == self then
			self:update()
			local raw = self.raw
			return math.abs(raw) > math.abs(rawThreshold or self.threshold*self.max) and raw or 0
		else
			return 0
		end
	end,
	--- Return the raw max of the input.
	-- @treturn number the input raw max
	max = function(self)
		self:update()
		return self.max
	end,

	--- Sets the default triggering threshold, i.e. how the minimal axis value for which the associated buttons will be considered down.
	-- 0.5 by default.
	-- @tparam number new the new triggering threshold
	-- @treturn AxisInput this AxisInput object
	triggeringThreshold = function(self, new)
		self.triggeringThreshold = tonumber(new)
		return self
	end,

	--- The associated button pressed when the axis reaches a positive value.
	positive = nil,
	--- The associated button pressed when the axis reaches a negative value.
	negative = nil,

	--- Update axis state.
	-- Automatically called, don't call unless you know what you're doing.
	-- @impl ubiquitousse
	update = function(self)
		if not updated[self] then
			local val, raw, max = 0, 0, 1
			for _, d in ipairs(self.detectors) do
				local v, r, m = d() -- v[-1,1], r[-m,+m]
				if math.abs(v) > math.abs(val) then
					val, raw, max = v, r or v, m or 1
				end
			end
			self.dval = val - self.val
			self.val, self.raw, self.max = val, raw, max
			updated[self] = true
		end
	end,

	--- LÖVE note: other callbacks that are defined in backend/love.lua and need to be called in the associated LÖVE callbacks.
}
axis_mt.__index = axis_mt

--- PointerInput methods
-- @impl ubiquitousse
local pointer_mt = {
	--- Returns a new PointerInput with the same properties.
	-- @treturn PointerInput the cloned object
	clone = function(self)
		return input.pointer(unpack(self.detectors))
		       :dimensions(self.width, self.height)
		       :offset(self.offsetX, self.offsetY)
		       :speed(self.xSpeed, self.ySpeed)
	end,

	--- Bind new axis couples to this input.
	-- @tparam table{mode,XAxis,YAxis} ... couples of axis detectors, axis identifiers or axis input to add and in which mode
	-- @treturn PointerInput this PointerInput object
	bind = function(self, ...)
		for _, p in ipairs({...}) do
			if type(p) == "table" then
				local h, v = p[2], p[3]
				if getmetatable(h) ~= axis_mt then
					h = input.axis(h)
				end
				if getmetatable(v) ~= axis_mt then
					v = input.axis(v)
				end
				table.insert(self.detectors, { p[1], h, v })
			else
				error("Pointer detector must be a table")
			end
		end
		return self
	end,
	--- Unbind axis couple(s).
	-- @tparam table{mode,XAxis,YAxis} ... couples of axis detectors, axis identifiers or axis input to remove
	-- @treturn PointerInput this PointerInput object
	unbind = button_mt.unbind,
	--- Unbind all axis couple(s).
	-- @treturn PointerInput this PointerInput object
	clear = button_mt.clear,

	--- Hijacks the input.
	-- This function returns a new input object which mirrors the current object, except it will hijack every new input.
	-- This means any value change will only be visible to the new object; the pointer will always appear to be at offsetX,offsetY for the initial object.
	-- An input can be hijacked several times; the one which hijacked it last will be the active one.
	-- @treturn PointerInput the new input object which is hijacking the input
	hijack = function(self)
		local hijacked
		hijacked = {
			horizontal = input.axis(function()
				local h = hijacked:x()
				local width = hijacked.width
				return h/width, h, width
			end),
			vertical = input.axis(function()
				local v = hijacked:y()
				local height = hijacked.height
				return v/height, v, height
			end)
		}
		hijacked.right, hijacked.left = hijacked.horizontal.positive, hijacked.horizontal.negative
		hijacked.up, hijacked.down = hijacked.vertical.negative, hijacked.vertical.positive
		setmetatable(hijacked, { __index = self, __newindex = self })
		table.insert(self.hijackStack, hijacked)
		self.hijacking = hijacked
		return hijacked
	end,
	--- Free the input that was hijacked by this object.
	-- Input will be given back to the previous object.
	-- @treturn PointerInput this PointerInput object
	free = button_mt.free,

	--- Set the moving area half-dimensions.
	-- Call without argument to use half the window dimensions.
	-- It's the half dimensions because axes values goes from -1 to 1, so theses dimensions only
	-- covers values from x=0,y=0 to x=1,y=1. The full moving area will be 4*newWidth*newHeight.
	-- @tparam number newWidth new width
	-- @tparam number newHeight new height
	-- @treturn PointerInput this PointerInput object
	dimensions = function(self, newWidth, newHeight)
		self.width, self.height = newWidth, newHeight
		return self
	end,
	--- Set the moving area coordinates offset.
	-- The offset is a value automatically added to the x and y values when using the x() and y() methods.
	-- Call without argument to automatically offset so 0,0 <= x(),y() <= width,height, i.e. offset to width,height.
	-- @tparam number newOffX new X offset
	-- @tparam number newOffY new Y offset
	-- @treturn PointerInput this PointerInput object
	offset = function(self, newOffX, newOffY)
		self.offsetX, self.offsetY = newOffX, newOffY
		return self
	end,
	--- Set maximal speed (pixels-per-milisecond)
	-- Only used in relative mode.
	-- Calls without argument to use the raw data and don't apply a speed modifier.
	-- @tparam number newXSpeed new X speed
	-- @tparam number newYSpeed new Y speed
	-- @treturn PointerInput this PointerInput object
	speed = function(self, newXSpeed, newYSpeed)
		self.xSpeed, self.ySpeed = newXSpeed, newYSpeed or newXSpeed
		return self
	end,

	--- Returns the current X value of the pointer.
	-- @treturn number X value
	x = function(self)
		if self.hijacking == self then
			self:update()
			return self.valX + (self.offsetX or self.width or input.getDrawWidth()/2)
		else
			return self.offsetX or self.width or input.getDrawWidth()/2
		end
	end,
	--- Returns the current Y value of the pointer.
	-- @treturn number Y value
	y = function(self)
		if self.hijacking == self then
			self:update()
			return self.valY + (self.offsetY or self.height or input.getDrawHeight()/2)
		else
			return self.offsetY or self.height or input.getDrawHeight()/2
		end
	end,

	--- Returns the X and Y value of the pointer, clamped.
	-- They are clamped to stay in the ellipse touching all 4 sides of the dimension rectangle, i.e. the
	-- (x,y) vector's magnitude reached its maximum either in (0,height) or (width,0).
	-- Typically, this is used with square dimensions for player movements: when moving diagonally, the magnitude
	-- will be the same as when moving horiontally or vertically, thus avoiding faster diagonal movement, A.K.A. "straferunning".
	-- If you're not conviced by my overly complicated explanation: just use this to retrieve x and y for movement and everything
	-- will be fine.
	-- @treturn number X value
	-- @treturn number Y value
	clamped = function(self)
		local width, height = self.width, self.height
		if self.hijacking == self then
			self:update()
			local x, y = self.valX, self.valY
			local cx, cy = x, y
			local normalizedMagnitude = (x*x)/(width*width) + (y*y)/(height*height) -- go back to a unit circle
			if normalizedMagnitude > 1 then
				local magnitude = sqrt(x*x + y*y)
				cx, cy = cx / magnitude * width, cy / magnitude * height
			end
			return cx + (self.offsetX or width or input.getDrawWidth()/2), cy + (self.offsetY or height or input.getDrawHeight()/2)
		else
			return self.offsetX or width or input.getDrawWidth()/2, self.offsetY or height or input.getDrawHeight()/2
		end
	end,

	--- The associated horizontal axis.
	horizontal = nil,
	--- The associated vertical axis.
	vertical = nil,

	--- The associated button pressed when the pointer goes to the right.
	right = nil,
	--- The associated button pressed when the pointer goes to the left.
	left = nil,
	--- The associated button pressed when the pointer points up.
	up = nil,
	--- The associated button pressed when the pointer points down.
	down = nil,

	--- Update pointer state.
	-- Automatically called, don't call unless you know what you're doing.
	-- @impl ubiquitousse
	update = function(self)
		if not updated[self] then
			local x, y = self.valX, self.valY
			local xSpeed, ySpeed = self.xSpeed, self.ySpeed
			local width, height = self.width or input.getDrawWidth()/2, self.height or input.getDrawHeight()/2
			local newX, newY = x, y
			local maxMovX, maxMovY = 0, 0 -- the maxium axis movement in a direction (used to determine which axes have the priority) (absolute value)
			for _, pointer in ipairs(self.detectors) do
				local mode, xAxis, yAxis = unpack(pointer)
				if mode == "relative" then
					local movX, movY = math.abs(xAxis:value()), math.abs(yAxis:value())
					if movX > maxMovX then
						newX = x + (xSpeed and (xAxis:value() * xSpeed * dt) or xAxis:raw())
						maxMovX = movX
					end
					if movY > maxMovY then
						newY = y + (ySpeed and (yAxis:value() * ySpeed * dt) or yAxis:raw())
						maxMovY = movY
					end
				elseif mode == "absolute" then
					local movX, movY = math.abs(xAxis:delta()), math.abs(yAxis:delta())
					if movX > maxMovX then
						newX = xAxis:value() * width
						maxMovX = movX
					end
					if movY > maxMovY then
						newY = yAxis:value() * height
						maxMovY = movY
					end
				end
			end
			self.valX, self.valY = math.min(math.abs(newX), width) * (newX < 0 and -1 or 1), math.min(math.abs(newY), height) * (newY < 0 and -1 or 1)
			updated[self] = true
		end
	end
}
pointer_mt.__index = pointer_mt

--- Input stuff
-- Inspired by Tactile by Andrew Minnich (https://github.com/tesselode/tactile), under the MIT license.
-- Ubiquitousse considers two basic input methods, called buttons (binary input) and axes (analog input).
input = {
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
	-- @impl backend
	basicButtonDetector = function(str) end,

	--- Make a new button detector from a detector function, string, or list of buttons.
	-- @tparam string, function button identifier
	-- @impl ubiquitousse
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
	-- @impl backend
	basicAxisDetector = function(str) end,

	--- Make a new axis detector from a detector function, string, or a couple of buttons.
	-- @tparam string, function or table axis identifier
	-- @impl ubiquitousse
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

	------------------------------------------
	--- Inputs (the thing you want to use) ---
	------------------------------------------

	-- Buttons inputs --
	-- Button input is a container for buttons detector. A button will be pressed when one of its detectors returns true.
	-- Inputs also knows if the button was just pressed or released.
	-- @tparam ButtonDetectors ... all the buttons detectors or buttons identifiers
	-- @tretrun ButtonInput the object
	-- @impl ubiquitousse
	button = function(...)
		local r = setmetatable({
			hijackStack = {}, -- hijackers stack, last element is the object currently hijacking this input
			hijacking = nil, -- object currently hijacking this input
			detectors = {}, -- detectors list
			state = "none" -- current state (none, pressed, down, released)
		}, button_mt)
		table.insert(r.hijackStack, r)
		r.hijacking = r
		r:bind(...)
		return r
	end,

	-- Axis inputs --
	-- Axis input is a container for axes detector. An axis input will return the value of the axis detector the most far away from their center (0).
	-- Axis input provide a threshold setting; every axis which has a distance to the center below the threshold (none by default) will be ignored.
	-- @tparam AxisDetectors ... all the axis detectors or axis identifiers
	-- @tretrun AxisInput the object
	-- @impl ubiquitousse
	axis = function(...)
		local r = setmetatable({
			hijackStack = {}, -- hijackers stack, last element is the object currently hijacking this input
			hijacking = nil, -- object currently hijacking this input
			detectors = {}, -- detectors list
			val = 0, -- current value between -1 and 1
			dval = 0, -- change between -2 and 2
			raw = 0, -- raw value between -max and +max
			max = 1, -- maximum for raw values
			threshold = 0, -- ie., the deadzone
			triggeringThreshold = 0.5 -- digital button threshold
		}, axis_mt)
		table.insert(r.hijackStack, r)
		r.hijacking = r
		r:bind(...)
		r.positive = input.button(function() return r:value() > r.triggeringThreshold end)
		r.negative = input.button(function() return r:value() < r.triggeringThreshold end)
		return r
	end,

	-- Pointer inputs --
	-- Pointer inputs are container for two axes input, in order to represent a two-dimensionnal pointing device, e.g. a mouse or a stick.
	-- Each pointer detector is a table with 3 fields: mode(string), XAxis(axis), YAxis(axis). mode can either be "relative" or "absolute".
	-- In relative mode, the pointer will return the movement since last update (for example to move a mouse pointer with a stick).
	-- In absolute mode, the pointer will return the pointer position directly deduced of the current axes position.
	-- @tparam table{mode,XAxis,YAxis} ... couples of axis detectors, axis identifiers or axis input to add and in which mode
	-- @tretrun PointerInput the object
	-- @impl ubiquitousse
	pointer = function(...)
		local r = setmetatable({
			hijackStack = {}, -- hijackers stack, first element is the object currently hijacking this input
			hijacking = nil, -- object currently hijacking this input
			detectors = {}, -- pointers list (composite detectors)
			valX = 0, valY = 0, -- pointer position
			width = 1, height = 1, -- half-dimensions of the movement area
			offsetX = 0, offsetY = 0, -- offsets
			xSpeed = 1, ySpeed = 1, -- speed (pixels/milisecond); for relative mode
		}, pointer_mt)
		table.insert(r.hijackStack, r)
		r.hijacking = r
		r:bind(...)
		r.horizontal = input.axis(function()
			local h = r:x()
			local width = r.width
			return h/width, h, width
		end)
		r.vertical = input.axis(function()
			local v = r:y()
			local height = r.height
			return v/height, v, height
		end)
		r.right, r.left = r.horizontal.positive, r.horizontal.negative
		r.up, r.down = r.vertical.negative, r.vertical.positive
		return r
	end,

	------------------------------
	--- Input detection helpers --
	------------------------------
	-- TODO: make this better

	--- Returns a list of the buttons currently in use, identified by their string button identifier.
	-- This may also returns "axis threshold" buttons if an axis passes the threshold.
	-- @tparam[opt=0.5] number threshold the threshold to detect axes as button
	-- @treturn string,... buttons identifiers list
	-- @impl backend
	buttonUsed = function(threshold) end,

	--- Returns a list of the axes currently in use, identified by their string axis identifier
	-- @tparam[opt=0.5] number threshold the threshold to detect axes
	-- @treturn string,... axes identifiers list
	-- @impl backend
	axisUsed = function(threshold) end,

	--- Returns a nice name for the button identifier.
	-- Can be locale-depedant and stuff, it's only for display.
	-- May returns the raw identifier if you're lazy.
	-- @tparam string... button identifier string(s)
	-- @treturn string... the displayable names
	-- @impl backend
	buttonName = function(...) end,

	--- Returns a nice name for the axis identifier.
	-- Can be locale-depedant and stuff, it's only for display.
	-- May returns the raw identifier if you're lazy.
	-- @tparam string... axis identifier string(s)
	-- @treturn string... the displayable names
	-- @impl backend
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
	-- @impl mixed
	default = {
		pointer = nil, -- Pointer: used to move and select. Example binds: arrow keys, WASD, stick.
		confirm = nil, -- Button: used to confirm something. Example binds: Enter, A button.
		cancel = nil -- Button: used to cancel something. Example binds: Escape, B button.
	},

	--- Get draw area dimensions.
	-- Used for pointers.
	-- @impl backend
	getDrawWidth = function() return 1 end,
	getDrawHeight = function() return 1 end,

	--- Update all the Inputs.
	-- Should be called at every game update. If ubiquitousse.signal is available, will be bound to the "update" signal in signal.event.
	-- The backend can hook into this function to to its input-related updates.
	-- @tparam numder dt the delta-time
	-- @impl ubiquitousse
	update = function(newDt)
		dt = newDt
		updated = {}
	end

	--- If you use LÖVE, note that in order to provide every feature (especially key detection), several callbacks functions will
	-- need to be called on LÖVE events. See backend/love.lua.
	-- If ubiquitousse.signal is available, these callbacks will be bound to signals in signal.event (with the same name as the LÖVE
	-- callbacks, minux the "love.").
}

-- Create default inputs
input.default.pointer = input.pointer()
input.default.confirm = input.button()
input.default.cancel = input.button()

-- Bind signals
if signal then
	signal.event:bind("update", input.update)
end

return input
