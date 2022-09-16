--- Input management facilities.
--
-- The module returns a single function, `input`.
--
-- **Requires** ubiquitousse.signal.
-- @module input
-- @usage
-- TODO

local signal = require((...):gsub("input%.input$", "signal"))
local event = require((...):gsub("input$", "event"))

local abs, sqrt, floor, ceil, min, max = math.abs, math.sqrt, math.floor, math.ceil, math.min, math.max

-- TODO:
-- friendly name for sources
-- write doc, incl how to define your own source and source expressions, default inputs

-- Always returns 0.
local function zero() return 0 end

local function loadexp(exp, env)
	local fn
	if loadstring then
		fn = assert(loadstring("return "..exp, "input expression"))
		setfenv(fn, env)
	else
		fn = assert(load("return "..exp, "input expression", "t", env))
	end
	return fn
end

-- Set a value in a table using its path string.
local function setPath(t, path, val)
	for part in path:gmatch("(.-)%.") do
		assert(t[part])
		t = t[part]
	end
	t[path:match("[^%.]+$")] = val
end
local function ensurePath(t, path, default)
	for part in path:gmatch("(.-)%.") do
		if not t[part] then t[part] = {} end
		t = t[part]
	end
	local final = path:match("[^%.]+$")
	if not t[final] then
		t[final] = default
	end
end

-- Functions available in input expressions.
local expressionEnv
expressionEnv = {
	floor = floor,
	ceil = ceil,
	abs = abs,
	clamp = function(x, xmin, xmax)
		return min(max(x, xmin), xmax)
	end,
	min = function(x, y, ...)
		local m = min(x, y)
		if ... then
			return expressionEnv.min(m, ...)
		else
			return m
		end
	end,
	max = function(x, y, ...)
		local m = max(x, y)
		if ... then
			return expressionEnv.max(m, ...)
		else
			return m
		end
	end,
	deadzone = function(x, deadzone)
		if abs(x) < deadzone then
			return 0
		end
		return x
	end
}

-- List of modifiers that can be applied to a source in an expression
local sourceModifiers = { "passive", "active" }
for _, mod in ipairs(sourceModifiers) do
	expressionEnv[mod] = function(...) return ... end
end

local input_mt

--- Make a new input object.
-- t: input configuration table (optional)
-- @function input
local function make_input(t)
	local self = setmetatable({
		config = t or {},
		children = {},
		event = signal.new(),
		_sourceCache = {},
		_event = signal.group(),
		_afterFilterEvent = signal.new(),
		_boundSourceEvents = {}
	}, input_mt)
	self:reload()
	return self
end

--- Input methods.
-- @type Input
input_mt = {
	--- Input configuration table.
	-- It can be used to recreate this input object later (by passing the table as an argument for the input constructor).
	-- This table does not contain any userdata and should be easily serializable (e.g. to save custom input binding config).
	-- This doesn't include input state, grab state, the event registry and the selected joystick since they may change often during runtime.
	-- Can be changed anytime, but you may need to call `reload` to apply changes.
	-- @usage
	-- player.config = {
	--   "key.a", "key.d - key.a", {"key.left + x", x=0.5}, -- list of input sources expressions
	--   jump = {...}, -- children input
	--   deadzone = 0.05, -- The deadzone for analog inputs (e.g. joystick axes): if the input absolute value is strictly below this, it will be considered as 0.
	--   threshold = 0.05 -- The pressed threshold: an input is considered down if above or equal to this value.
	-- }
	config = {},
	--- List and map of children inputs.
	-- {[child1.name]=child1, [child2.name]=child2, child1, child2...}
	children = {},
	--- Name of the input.
	-- Defined on children inputs only.
	name = nil,

	--- False if the input is currently not grabbed, a subinput otherwise.
	-- This may be different between each subinput.
	grabbed = false,
	--- False if the input is not a subinput, the input it grabbed otherwise.
	-- This may be different between each subinput.
	grabbing = false,
	--- Input event registry.
	-- The following events are available:
	--
	-- * `"moved"`: called when the input value change, with arguments (new value, delta since last event)
	-- * `"pressed"`: called when the input is pressed
	-- * `"released"`: called when the input is released
	--
	-- For pointer inputs (have a "horizontal" and "vertical" children inputs) is also avaible:
	--
	-- * `"pointer moved"`: called when the pointer position change, with arguments (new pointer x, new pointer y, delta x since last event, delta y since last event)
	--
	-- Each subinput has a different event registry.
	event = nil,

	-- Input state, independendant between each grab. Reset by :neutralize().
	_state = "none", -- none, pressed or released
	_value = 0, -- input value
	_prevValue = 0, -- value last frame

	-- Input state, shared between grabs.
	_event = nil, -- Event group for all event binded by this input.
	_sourceCache = {}, -- Map of the values currently taken by every source this input use.
	_afterFilterEvent = nil, -- Event registry that resend the source events after applying the eventual filter function.
	_boundSourceEvents = {}, -- Map of sources events that are binded (and thus will send events to _afterFilterEvent).
	_joystick = nil, -- Currently selected joystick for this player. Also shared with children inputs.

	--- Update the input and its children.
	-- Should be called every frame, typically _after_ you've done all your input handling
	-- (otherwise `pressed` and `released` may never return true and `delta` might be wrong).
	-- (Note: this should not be called on subinputs)
	update = function(self)
		self:_update()
		self._prevValue = self._value
		for _, i in ipairs(self.children) do
			i:update()
		end
	end,

	--- Create a new input object based on this input `config` data.
	clone = function(self)
		return make_input(self.config)
	end,

	--- Relond the input `config`, and do the same for its children.
	-- This will reenable the input if it was disabled using `disable`.
	reload = function(self)
		-- clear all events we bounded previously
		self._event:clear()
		self._boundSourceEvents = {}
		-- remove removed children
		for i=#self.children, 1, -1 do
			local c = self.children[i]
			if not self.config[c.name] then
				c:disable()
				table.remove(self.children, i)
			end
		end
		-- reload children
		for _, c in ipairs(self.children) do
			c:reload()
		end
		-- add added children
		for subname, subt in pairs(self.config) do
			if type(subname) == "string" and type(subt) == "table" and not rawget(self, subname) then
				local c = make_input(subt)
				c.name = subname
				table.insert(self.children, c)
				self.children[subname] = c
				self[subname] = c
			end
		end
		-- rebind source events
		for _, exp in ipairs(self.config) do
			-- extract args
			local args = {}
			if type(exp) == "table" then
				for k, v in pairs(exp) do
					if k ~= 1 then
						args[k] = v
					end
				end
				exp = exp[1]
			end
			-- build env
			local env = {}
			for k, v in pairs(args) do env[k] = v end
			setmetatable(env, {
				__index = function(t, key)
					if key == "value" then return self:value() end
					return self._sourceCache[key] or expressionEnv[key]
				end
			})
			-- extract sources
			local sources = {}
			local srcmt
			srcmt = { -- metamethods of sources values during the scanning process
				__add = zero, __sub = zero,
				__mul = zero, __div = zero,
				__mod = zero, __pow = zero,
				__unm = zero, __idiv = zero,
				__index = function(t, key)
					local i = rawget(t, 1)
					if i then sources[i][1] = sources[i][1] .. "." .. key
					else table.insert(sources, { key })
					end
					return setmetatable({ i or #sources }, srcmt)
				end
			}
			local scanEnv = setmetatable({ value = 0 }, { __index = srcmt.__index }) -- value is not a source
			for k, v in pairs(args) do scanEnv[k] = v end -- add args
			for k in pairs(expressionEnv) do scanEnv[k] = zero end -- add functions
			for _, mod in ipairs(sourceModifiers) do -- add modifiers functions
				scanEnv[mod] = function(source)
					assert(getmetatable(source) == srcmt, ("trying to apply %s modifier on a non-source value"):format(mod))
					sources[rawget(source, 1)][mod] = true
					return source
				end
			end
			loadexp(exp, scanEnv)() -- scan!
			-- set every source to passive if there is a dt source
			local hasDt = false
			for _, s in ipairs(sources) do
				if s[1] == "dt" then hasDt = true break end
			end
			if hasDt then
				for _, s in ipairs(sources) do
					if s[1] ~= "dt" and not s.active then
						s.passive = true
					end
				end
			end
			-- setup function
			local fn = loadexp(exp, env)
			-- init sources and bind to source events
			local boundAfterFilterEvent = {}
			local function onAfterFilterEvent(new) self:_update(fn()) end
			for _, s in ipairs(sources) do
				local sname = s[1]
				ensurePath(self._sourceCache, sname, 0)
				if not self._boundSourceEvents[sname] then
					if sname:match("^child%.") then
						local cname = sname:match("^child%.(.*)$")
						assert(self.children[cname], ("input expression refer to %s but this input has no child named %s"):format(sname, cname))
						self._event:bind(self.children[cname].event, "moved", function(new) -- child event -> self._afterFilterEvent link
							setPath(self._sourceCache, sname, new)
							self._afterFilterEvent:emit(sname, new)
						end)
					else
						self._event:bind(event, sname, function(new, filter, ...) -- event source -> self._afterFilterEvent link
							if filter then
								new = filter(self, new, ...)
								if not new then return end -- filtered out
							end
							setPath(self._sourceCache, sname, new)
							self._afterFilterEvent:emit(sname, new)
						end)
					end
					self._boundSourceEvents[sname] = true
				end
				if not boundAfterFilterEvent[sname] and not s.passive then
					self._event:bind(self._afterFilterEvent, sname, onAfterFilterEvent) -- self._afterFilterEvent -> input update link
					boundAfterFilterEvent[sname] = true
				end
			end
		end
		-- rebind pointer events
		if self.config.horizontal and self.config.horizontal then
			self._event:bind(self.horizontal.event, "moved", function(new, delta) self.event:emit("pointer moved", new, self.vertical:value(), delta, 0) end)
			self._event:bind(self.vertical.event, "moved", function(new, delta) self.event:emit("pointer moved", self.horizontal:value(), new, 0, delta) end)
		end
	end,
	--- Disable the input and its children, preventing further updates and events.
	-- The input can be reenabled using `reload`.
	disable = function(self)
		for _, c in ipairs(self.children) do
			c:disable()
		end
		self._event:clear()
	end,

	--- Will call fn(source) on the next activated source (including sources not currently used by this input).
	-- Typically used to detect an input in your game input binding settings.
	-- @param fn function that will be called on the next activated source matching the filter
	-- @param[opt] filter list of string patterns that sources must start with (example `{"button", "key"}` to only get buttons and key sources)
	onNextActiveSource = function(self, fn, filter)
		local function onevent(source, new, filterfn, ...)
			if filter then
				local ok = false
				for _, f in ipairs(filter) do
					if source:match("^"..f) then
						ok = true
						break
					end
				end
				if not ok then return end
			end
			if filterfn then
				new = filterfn(self, new, ...)
				if new == nil then return end
			end
			if abs(new) >= self:_threshold() then
				event:unbind("_active", onevent)
				fn(source)
			end
		end
		event:bind("_active", onevent)
	end,

	--- Grab the input and its children input and returns the new subinput.
	--
	-- A grabbed input will no longer update and instead pass all new update to the subinput.
	-- This is typically used for contextual action or pause menus: by grabbing the player input, all the direct use of
	-- this input in the game will stop (can't move caracter, ...) and instead you can use the subinput to handle input in the pause menu.
	-- To stop grabbing an input, you will need to `:release` the subinput.
	--
	-- This will also reset the input to a neutral state. The subinput will share everything with this input, except
	-- `grabbed`, `grabbing`, `event` (a new event registry is created), and of course its current state.
	grab = function(self)
		local g = {
			grabbed = false,
			grabbing = self,
			event = signal.new(),
			children = {}
		}
		for _, c in ipairs(self.children) do
			g[c.name] = c:grab()
			table.insert(g.children, g[c.name])
		end
		self:neutralize()
		self.grabbed = setmetatable(g, { __index = self })
		return g
	end,
	--- Release a subinput and its children.
	-- The parent grabbed input will be updated again. This subinput will be reset to a neutral position and won't be updated further.
	release = function(self)
		assert(self.grabbing, "not a grabbed input")
		for _, c in ipairs(self.children) do
			c:release()
		end
		self:neutralize()
		self.grabbing.grabbed = false
		self.grabbing = false
	end,

	--- Set the state of this input to a neutral position (i.e. value = 0).
	neutralize = function(self)
		self:_update(0)
		self._state = "none"
		self._value = 0
		self._prevValue = 0
	end,

	--- Set the joystick associated with this input.
	-- The input will ignore every other joystick.
	-- Set joystick to `nil` to disable and get input from every connected joystick.
	-- @param joystick LÖVE jostick object to associate
	setJoystick = function(self, joystick)
		self._joystick = joystick
		for _, i in ipairs(self.children) do
			i:setJoystick(joystick)
		end
	end,
	--- Returns the currently selected joystick.
	getJoystick = function(self)
		return self._joystick
	end,

	--- Returns true if the input is currently down.
	down = function(self)
		return self._state == "down" or self._state == "pressed"
	end,
	--- Returns true if the input has just been pressed.
	pressed = function(self)
		return self._state == "pressed"
	end,
	--- Returns true if the input has just been released.
	released = function(self)
		return self._state == "released"
	end,
	--- Returns the current value of the input.
	value = function(self)
		return self._value
	end,
	--- Returns the delta value of the input since the last call to `update`.
	delta = function(self)
		return self._value - self._prevValue
	end,
	--- If there is a horizontal and vertical children inputs, this returns the horizontal value and the vertical value.
	-- Typically used for movement/axes pairs (e.g. to get x,y of a stick or directional pad).
	pointer = function(self)
		return self.horizontal:value(), self.vertical:value()
	end,
	--- Same as `pointer`, but normalize the returned vector, i.e. "clamp" the returned x,y coordinates into a circle of radius 1.
	-- Typically used to avoid faster movement on diagonals
	-- (as if both horizontal and vertical values are 1, the pointer vector has √2 magnitude, higher than the 1 magnitude of a purely vertical or horizontal movement).
	clamped = function(self)
		local x, y = self:pointer()
		local mag = x*x + y*y
		if mag > 1 then
			local d = sqrt(mag)
			return x/d, y/d
		else
			return x, y
		end
	end,

	-- Update the state of the input: called at least on every input value change and on :update().
	-- new: new value of the input if it has changed (number, can be anything, but typically in [0-1]) (optional)
	_update = function(self, new)
		if self.grabbed then
			self.grabbed:_update(new) -- pass onto grabber
		else
			local threshold = self:_threshold()
			-- update values
			new = new or self._value
			local old = self._value
			self._value = new
			-- update state and emit events
			local delta = new - old
			if delta ~= 0 then
				self.event:emit("moved", new, delta)
			end
			if abs(new) >= threshold then
				if abs(old) < threshold then
					self._state = "pressed"
					self.event:emit("pressed")
				else
					self._state = "down"
				end
			else
				if abs(old) >= threshold then
					self._state = "released"
					self.event:emit("released")
				else
					self._state = "none"
				end
			end
		end
	end,
	-- Returns the deadzone of the input.
	_deadzone = function(self)
		return self.config.deadzone or 0.05
	end,
	-- Returns the threshold of the input.
	_threshold = function(self)
		return self.config.threshold or 0.05
	end,
}
input_mt.__index = input_mt

return make_input
