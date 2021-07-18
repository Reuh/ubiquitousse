local input = require((...):gsub("axis$", "input"))
local button_mt = require((...):gsub("axis$", "button"))

--- AxisInput methods
local axis_mt
axis_mt = {
	-- Axis inputs --
	-- Axis input is a container for axes detector. An axis input will return the value of the axis detector the most far away from their center (0).
	-- Axis input provide a threshold setting; every axis which has a distance to the center below the threshold (none by default) will be ignored.
	-- @tparam AxisDetectors ... all the axis detectors or axis identifiers
	-- @tretrun AxisInput the object
	_new = function(...)
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
		r.negative = input.button(function() return r:value() < -r.triggeringThreshold end)
		return r
	end,

	--- Returns a new AxisInput with the same properties.
	-- @treturn AxisInput the cloned object
	clone = function(self)
		return input.axis(unpack(self.detectors))
		       :threshold(self.threshold)
		       :triggeringThreshold(self.triggeringThreshold)
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
			negative = input.button(function() return hijacked:value() < -self.triggeringThreshold end)
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
	update = function(self)
		if not input.updated[self] then
			local val, raw, max = 0, 0, 1
			for _, d in ipairs(self.detectors) do
				local v, r, m = d() -- v[-1,1], r[-m,+m]
				if math.abs(v) > math.abs(val) then
					val, raw, max = v, r or v, m or 1
				end
			end
			self.dval = val - self.val
			self.val, self.raw, self.max = val, raw, max
			input.updated[self] = true
		end
	end,

	--- LÖVE note: other callbacks that are defined in backend/love.lua and need to be called in the associated LÖVE callbacks.
}
axis_mt.__index = axis_mt

return axis_mt
