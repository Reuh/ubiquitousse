local input = require((...):gsub("button$", "input"))

--- ButtonInput methods
local button_mt
button_mt = {
	-- Buttons inputs --
	-- Button input is a container for buttons detector. A button will be pressed when one of its detectors returns true.
	-- Inputs also knows if the button was just pressed or released.
	-- @tparam ButtonDetectors ... all the buttons detectors or buttons identifiers
	-- @tretrun ButtonInput the object
	_new = function(...)
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
	update = function(self)
		if not input.updated[self] then
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
			input.updated[self] = true
		end
	end
}
button_mt.__index = button_mt

return button_mt
