local input = require((...):gsub("pointer$", "input"))
local button_mt = require((...):gsub("pointer$", "button"))
local axis_mt = require((...):gsub("pointer$", "axis"))

local sqrt = math.sqrt

--- PointerInput methods
local pointer_mt
pointer_mt = {
	-- Pointer inputs --
	-- Pointer inputs are container for two axes input, in order to represent a two-dimensionnal pointing device, e.g. a mouse or a stick.
	-- Each pointer detector is a table with 3 fields: mode(string), XAxis(axis), YAxis(axis). mode can either be "relative" or "absolute".
	-- In relative mode, the pointer will return the movement since last update (for example to move a mouse pointer with a stick).
	-- In absolute mode, the pointer will return the pointer position directly deduced of the current axes position.
	-- @tparam table{mode,XAxis,YAxis} ... couples of axis detectors, axis identifiers or axis input to add and in which mode
	-- @tretrun PointerInput the object
	_new = function(...)
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
	update = function(self)
		if not input.updated[self] then
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
						newX = x + (xSpeed and (xAxis:value() * xSpeed * input.dt) or xAxis:raw())
						maxMovX = movX
					end
					if movY > maxMovY then
						newY = y + (ySpeed and (yAxis:value() * ySpeed * input.dt) or yAxis:raw())
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
			input.updated[self] = true
		end
	end
}
pointer_mt.__index = pointer_mt

return pointer_mt
