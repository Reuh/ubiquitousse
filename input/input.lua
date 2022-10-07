--[[- Input management facilities.

The module returns a single function, `input`.

You can find in the module `uqt.input.default` (in file `input/default.lua`) some common input configuration for
2D movement, confirmation and cancellation (for both keyboard and joystick). Feel free to
use them as-is, or as a base for your own inputs.

**Requires** ubiquitousse.signal.

@module input
@usage
local input = require("ubiquitousse.input")

-- Joystick-only control for player 1
local player1 = {
	move = {
		-- 2D movement, clamped on a circle
		"clamped(child.right - child.left, child.down - child.up)",
		dimension = 2,

		-- All the directions we can go, using both the left joystick and the D-pad
		right = { "axis.leftx.p", "button.dpright" },
		left = { "axis.leftx.n", "button.dpleft" },
		down = { "axis.lefty.p", "button.dpdown" },
		up = { "axis.lefty.n", "button.dpup" }
	},

	fire = { "button.a" }
}

-- Only consider inputs from the first joystick (in practice you will want to check if the joystick exists before running this line)
player1:setJoystick(love.joystick.getJoysticks()[1])

-- Player 2, using a second gamepad!
local player2 = player1:clone()
player2:setJoystick(love.joystick.getJoysticks()[2])

-- Define input callbacks.
player1.fire.event:bind("pressed", function() print("player 1 starts firing!") end)
player1.fire.event:bind("released", function() print("player 1 stop firing...") end)

function love.update()
	-- Get player 1's 2D movement
	local x, y = player1.move:value()
	movePlayer1(x, y)

	-- Check current state of the firing input
	if player1.fire:down() then
		-- currently firing!
	end

	-- Update inputs.
	player1:update()
	player2:update()
end
--]]

local signal = require((...):gsub("input%.input$", "signal"))
local event = require((...):gsub("input$", "event"))

local abs, sqrt, floor, ceil, min, max = math.abs, math.sqrt, math.floor, math.ceil, math.min, math.max
local unpack = table.unpack or unpack

-- TODO: friendly name for sources

-- TODO: way to handle text input
-- don't want to change how everything is number based here (it's clean), but would be ok to eg give an additionnal metdatat (text string) along with the "text key pressed" input

-- TODO: might be interesting to allow for some outputs, like rumble for a player's joystick?

-- Table to contain temporary calculations (mainly to compute input deltas without needing to allocate a new table).
-- Note that this table is never cleared; don't fill it with large data and don't assume its length.
local tmp = {}

-- Always returns 0.
local function zero() return 0 end

-- Load a Lua expression string into a function.
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

local input_mt

--- Make a new input object.
--
-- This constructor is returned by the `uqt.input` module.
--
-- @tparam[opt] table config input configuration table, see `Input.config`
-- @treturn Input Input object
-- @usage
-- local player = uqt.input {
--    fire = { "key.a" },
--    jump = { "key.space" }
-- }
-- player.fire.event:bind("pressed", function() print("pew pew") end)
-- @function input
local function make_input(t)
	local self = setmetatable({
		config = t or {},
		children = {},
		event = signal.new(),
		_value = { 0 },
		_prevValue = { 0 },
		_sourceCache = {},
		_event = signal.group(),
		_afterFilterEvent = signal.new(),
		_boundSourceEvents = {}
	}, input_mt)
	self:reload()
	return self
end

--- Input expressions.
--
-- Each `Input` is associated with a list of *input expressions*.
--
-- An input expression is a `string` representing a valid Lua expression.
-- These Lua expressions are used to compute the values returned by the input.
-- An input expression should returns as many values as the dimension of its input.
--
-- When referring to a variable in an expression, it will be interpreted as an *input source*.
-- An input source is where the initial input data comes from: for example, an input source could be the current state of
-- the Q key: `"key.q"` (=1 when the key is down, 0 otherwise).
-- See [sources](#Input_sources) for details on how to define sources and built-in sources.
--
-- When a source that is present is the expression is updated, the input will be automatically updated in a reactive way, unless
-- the input is *passive* - that is, it can not trigger input update.
--
-- Additionally, you can also define your own variables to be used in input expression by giving arguments.
--
-- In input expression, you have no access to the Lua standard library; some other, more specific functions are available instead
-- and described below.
--
-- @usage
-- -- Example input configs for various input expression features.
-- fire = {
--    -- Basic input expression: 1 when Q is pressed, 0 otherwise. Will automatically update when Q is pressed.
--    "key.q",
--    -- Example using two inputs sources: when either A or Q is pressed, this will update, and returns 1 is at least one of them is pressed.
--    "max(key.q, key.a)",
--    -- This input has two input expression: it will be updated when either of them is updated and keep the value of the expression that was updated last.
-- }
-- horizontal = {
--    -- Another example, typically used to define an input for horizontal movement: returns 1 when pressing only right, -1 when pressing only left, and 0 otherwise.
--    "key.right - key.left",
-- }
-- arguments = {
--    -- You can give arguments to an expression by wrapping the expression in a table containing the arguments.
--    { "axis.leftx + offset", offset = 1 }
-- }
-- passive = {
--   -- Same as the example above, but this will only update when Q is pressed - pressing A will not update the input on its own.
--   -- Passive input are typically used for modifiers keys (shift, alt, etc.) that should not trigger an update when pressed on their own.
--   "max(key.q, passive(key.a))"
-- }
-- dimension = {
--   -- A two-dimensional input should have input expressions that return two values.
--   -- Here a common example that could be used to move something in 2D.
--   "key.right - key.left, key.down - key.up",
--   dimension = 2
-- }
-- mouse = {
--   -- Example input that returns the position of the mouse cursor, that can be controlled both using an actual mouse or
--   -- through a joystick.
--   dimension = 2,
--   "mouse.x, mouse.y",
--   { "value[1] + axis.leftx * speed * dt, value[2] + axis.lefty * speed * dt", speed = 300 } -- contains dt, so updated only once per frame. Thus speed here is the speed in pixel/second, as expected.
-- }
-- mouse = {
--   -- A special case: if the `dt` source is present in an expression, it will make every other input source passive by default in the expression.
--   -- This is the case since `dt` will trigger an update every frame, and is therefore mostly relevant for input that is used once per frame only
--   -- (while other input sources might cause the input to update several times per frame).
--   "axis.leftx * dt"
-- }
-- child = {
--   -- Children input can be used as input sources using the `child.name` syntax.
--   -- If the children input has more than one dimension, you will need to specify it using a numeric index like `child.fire[2]` (for the dimension 2 of the child).
--   "child.fire",
--   fire = { "key.q" }
--}
-- @section Expressions
local expressionEnv
expressionEnv = {
	--- Same as Lua's `math.floor`.
	-- @function floor
	-- @tparam number x number to round
	-- @treturn number floored value
	floor = floor,
	--- Same as Lua's `math.ceil`.
	-- @function floor
	-- @tparam number x number to round
	-- @treturn number ceiled value
	ceil = ceil,
	--- Same as Lua's `math.abs`.
	-- @function floor
	-- @tparam number x number to absolute
	-- @treturn number absolute value
	abs = abs,
	--- Clamp x between xmin and xmax.
	-- @tparam number x number clamp
	-- @tparam number xmin minimal value
	-- @tparam number xmax maximal value
	-- @treturn number clamped value
	clamp = function(x, xmin, xmax)
		return min(max(x, xmin), xmax)
	end,
	--- Returns the minimal value among all parameters.
	-- @tparam number x first value
	-- @tparam number y second value
	-- @tparam number ... other values
	-- @treturn number smallest value among the arguments
	min = function(x, y, ...)
		local m = min(x, y)
		if ... then
			return expressionEnv.min(m, ...)
		else
			return m
		end
	end,
	--- Returns the maximal value among all parameters.
	-- @tparam number x first value
	-- @tparam number y second value
	-- @tparam number ... other values
	-- @treturn number biggest value among the arguments
	max = function(x, y, ...)
		local m = max(x, y)
		if ... then
			return expressionEnv.max(m, ...)
		else
			return m
		end
	end,
	--- If x < deadzone, returns 0; otherwise returns the value.
	-- @tparam number x value
	-- @tparam number deadzone deadzone
	-- @treturn number 0 if x < deadzone; x otherwise
	deadzone = function(x, deadzone)
		if abs(x) < deadzone then
			return 0
		end
		return x
	end,
	--- Returns a normalized version of the vector (x,y), i.e. "clamp" the returned x,y coordinates into a circle of radius 1.
	-- Typically used to avoid faster movement on diagonals, as if both horizontal and vertical values are 1, the (1,1) vector has √2 magnitude, higher than the 1 magnitude of a purely vertical or horizontal movement.
	-- @tparam number x value
	-- @tparam number y value
	-- @treturn number clamped x value
	-- @treturn number clamped y value
	normalize = function(x, y)
		local mag = x*x + y*y
		if mag > 1 then
			local d = sqrt(mag)
			return x/d, y/d
		else
			return x, y
		end
	end,
	--- Mark an input source as passive.
	-- @function passive
	-- @tparam InputSource source input source to mark as passive
	-- @treturn InputSource the same input source
	passive = nil,
	--- Mark an input source as active.
	-- Note that input sources are active by default in most cases.
	-- @function passive
	-- @tparam InputSource source input source to mark as active
	-- @treturn InputSource the same input source
	active = nil
}

-- List of modifiers that can be applied to a source in an expression
local sourceModifiers = { "passive", "active" }
for _, mod in ipairs(sourceModifiers) do
	expressionEnv[mod] = function(...) return ... end
end

--- Input methods.
--
-- Methods and attributes available on Input objects. See `input` to create such an object.
-- @type Input
input_mt = {
	--- Input configuration table.
	--
	-- It can be used to recreate this input object later (by passing the table as an argument for the input constructor).
	-- This table does not contain any userdata and should be easily serializable (e.g. to save custom input binding config).
	-- This doesn't include input state, grab state, the event registry and the selected joystick since they may change often during runtime.
	--
	-- Can be changed anytime, but you will need to call `reload` to apply changes.
	--
	-- See [expressions](#Input_expressions) for an explanation on how to write input expressions.
	-- @usage
	-- player.config = {
	--	  -- list of input sources expressions: either a string, or a table to specify some arguments for the expression
	--   "key.a", "key.d - key.a", {"key.left + x", x=0.5},
	--   -- children input: the table take the same fields as this
	--   jump = {...},
	--   -- The deadzone for analog inputs (e.g. joystick axes): if the input absolute value is strictly below this, it will be considered as 0. 0.05 by default.
	--   -- This is applied automatically after the evaluation of input expressions.
	--   deadzone = 0.05,
	--   -- The pressed threshold: an input is considered down if above or equal to this value. 0.05 by default.
	--   -- This is considered when determining if the input is pressed, odwn and released.
	--   threshold = 0.05,
	--   -- Dimension of the input (i.e. the number of values returned by this input). 1 by default.
	--   dimension = 1
	-- }
	config = {},
	--- List and map of children `Input`s.
	--
	-- Takes the form `{[child1.name]=child1, [child2.name]=child2, child1, child2...}`.
	-- Each child input is present both an element of this list and as the value associated with its name in the table.
	--
	-- Note that children are *also* set directly on the input object for easier access.
	-- @usage
	-- local player = input{ fire = "button.a" }
	-- local fire = player.fire
	-- -- Is the same as:
	-- local fire = player.children.fire
	-- @ro
	children = {},
	--- Name of the input.
	-- Defined on children inputs only.
	-- @ftype string
	-- @ro
	name = nil,

	--- `false` if the input is disabled, `true` otherwise.
	-- If the input is disabled, its children are also disabled.
	-- @ro
	enabled = true,

	--- `false` if the input is currently not grabbed, the grabbing `Input` otherwise.
	-- @ro
	grabbed = false,
	--- `false` if the input is not grabbing another input, the `Input` it is grabbing from otherwise.
	-- @ro
	grabbing = false,

	--- Input event registry.
	-- The following events are available:
	--
	-- * `"moved"`: called when the input value change, with arguments `(new value, delta since last event)`. For inputs with dimension > 1, arguments are `(new value[1], new value[2], ..., delta[1], delta[2], ...)`.
	--
	-- * `"pressed"`: called when the input is pressed, with arguments `(1, new value, delta since last event)`. For inputs with dimension > 1, arguments are `(dimensions that was pressed, new value[1], new value[2], ..., delta[1], delta[2], ...)`.
	--
	-- * `"released"`: called when the input is released, with arguments `(1, new value, delta since last event)`. For inputs with dimension > 1, arguments are `(dimensions that was pressed, new value[1], new value[2], ..., delta[1], delta[2], ...)`.
	event = nil,

	-- Input state regarding current value. Reset by :neutralize().
	_state = "none", -- none, pressed or released
	_value = { 0 }, -- input value
	_prevValue = { 0 }, -- value last frame

	-- Input state, regarding events. Reset by :reload().
	_event = nil, -- Event group for all event binded by this input.
	_sourceCache = {}, -- Map of the values currently taken by every source this input use. Sources are expected to return a single number value.
	_afterFilterEvent = nil, -- Event registry that resend the source events after applying the eventual filter function.
	_boundSourceEvents = {}, -- Map of sources events that are binded (and thus will send events to _afterFilterEvent).

	-- Other input state.
	_joystick = nil, -- Currently selected joystick for this player. Also shared with children inputs.

	-- Cache computed directly from the input config. Recomputed by :reload().
	_dimension = 1, -- Dimension of the input.
	_deadzone = 0.05, -- Deadzone of the input.
	_threshold = 0.05, -- Threshold of the input.

	--- Update the input and its children.
	-- Should be called every frame, typically _after_ you've done all your input handling
	-- (otherwise `pressed` and `released` may never return true and `delta` might be wrong).
	--
	-- (Note: this should not be called on subinputs)
	update = function(self)
		self:_update()
		for i=1, self._dimension do
			self._prevValue[i] = self._value[i]
		end
		for _, i in ipairs(self.children) do
			i:update()
		end
	end,

	--- Create a new input object based on this input `config` data.
	clone = function(self)
		return make_input(self.config)
	end,

	--- Reload the input `config`, and do the same for its children.
	-- This will reenable the input if it was disabled using `disable`.
	reload = function(self)
		-- get main options
		self._dimension = self.config.dimension or 1
		self._deadzone = self.config.deadzone or 0.05
		self._threshold = self.config.threshold or 0.05
		-- resize dimensions
		if #self._value > self._dimension then
			for i=self._dimension+1, #self._value do
				self._value[i] = nil
				self._prevValue[i] = nil
			end
		elseif #self._value < self._dimension then
			for i=#self._value+1, self._dimension do
				self._value[i] = 0
				self._prevValue[i] = 0
			end
		end
		-- clear all events we bounded previously
		self._event:clear()
		self._boundSourceEvents = {}
		-- remove removed children
		for i=#self.children, 1, -1 do
			local c = self.children[i]
			if not self.config[c.name] then
				c:disable()
				table.remove(self.children, i)
				self.children[c.name] = nil
				self[c.name] = nil
			end
		end
		-- reload children
		for _, c in ipairs(self.children) do
			c.config = self.config[c.name]
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
					return self._sourceCache[key] or expressionEnv[key]
				end
			})
			-- extract sources and set initial values in _sourceCache
			local sources = {}
			local srcmt
			srcmt = { -- metamethods of sources values during the scanning process
				__add = zero, __sub = zero,
				__mul = zero, __div = zero,
				__mod = zero, __pow = zero,
				__unm = zero, __idiv = zero,
				__index = function(t, key)
					local i = rawget(t, "_")
					if i then -- has a parent source key
						local source = sources[i]
						local parentKey = source[#source]
						-- turn parent source into a table in the cache
						if source.parentCache[parentKey] == 0 then
							source.parentCache[parentKey] = {}
						end
						source.parentCache = source.parentCache[parentKey]
						-- set value in the cache for this source
						if not source.parentCache[key] then
							source.parentCache[key] = 0
						end
						-- add key to source name for this current object
						table.insert(source, key)
					else -- new root source key
						table.insert(sources, { key, parentCache = self._sourceCache })
						-- set value in the cache for this source
						if not self._sourceCache[key] then
							self._sourceCache[key] = 0
						end
					end
					return setmetatable({ _ = i or #sources }, srcmt)
				end
			}
			local scanEnv = setmetatable({}, { __index = srcmt.__index }) -- value is not a source
			for k, v in pairs(args) do scanEnv[k] = v end -- add args
			for k in pairs(expressionEnv) do scanEnv[k] = zero end -- add functions
			for _, mod in ipairs(sourceModifiers) do -- add modifiers functions
				scanEnv[mod] = function(source)
					assert(getmetatable(source) == srcmt, ("trying to apply %s modifier on a non-source value"):format(mod))
					sources[rawget(source, "_")][mod] = true
					return source
				end
			end
			loadexp(exp, scanEnv)() -- scan!
			-- build source names
			for _, s in ipairs(sources) do
				s.lastKey = s[#s] -- keep last key to allow setting the value in cache using parentCache[lastKey] = value
				for i, p in ipairs(s) do
					if type(p) == "string" then
						if i > 1 then
							s[i] = "." .. p
						end
					else
						s[i] = ("[%s]"):format(tostring(p))
					end
				end
				s.name = table.concat(s)
			end
			-- set every source to passive if there is a dt source
			local hasDt = false
			for _, s in ipairs(sources) do
				if s.name == "dt" then hasDt = true break end
			end
			if hasDt then
				for _, s in ipairs(sources) do
					if s.name ~= "dt" and not s.active then
						s.passive = true
					end
				end
			end
			-- setup function
			local fn = loadexp(exp, env)
			-- init sources and bind to source events
			local boundAfterFilterEvent = {}
			local function onAfterFilterEvent(new) self:_update{fn()} end
			for _, s in ipairs(sources) do
				local sname = s.name
				if not self._boundSourceEvents[sname] then
					if sname:match("^child%.") then
						local cname, index = sname:match("^child%.(.*)%[(%d+)%]$")
						if not cname then cname = sname:match("^child%.(.*)$") end
						local child = self.children[cname]
						assert(child, ("input expression refer to %q but this input has no child named %s"):format(sname, cname))
						if child._dimension > 1 then
							assert(index, ("input expression refer to %q without specifing a dimension but this child has more than one dimension"):format(sname))
						else
							assert(not index, ("input expression refer to %q but this child only has a single dimension"):format(sname))
						end
						local i = index and tonumber(index) or 1
						self._event:bind(self.children[cname].event, "moved", function(...) -- child event -> self._afterFilterEvent link
							local new = select(i, ...)
							s.parentCache[s.lastKey] = new
							self._afterFilterEvent:emit(sname, new)
						end)
					elseif sname:match("^value") then
						local index = sname:match("^value%[(%d+)%]$")
						if not index then assert(sname == "value", ("%q is not a valid source; value should be either \"value\" or \"value[number]\""):format(sname)) end
						s.passive = true
						if self._dimension > 1 then
							assert(index, ("input expression refer to %q without specifing a dimension but this input has more than one dimension"):format(sname))
						else
							assert(not index, ("input expression refer to %q but this input only has a single dimension"):format(sname))
						end
						local i = index and tonumber(index) or 1
						self._event:bind(self.event, "moved", function(...) -- self event -> self._afterFilterEvent link
							local new = select(i, ...)
							s.parentCache[s.lastKey] = new
							self._afterFilterEvent:emit(sname, new)
						end)
					else
						self._event:bind(event, sname, function(new, filter, ...) -- event source -> self._afterFilterEvent link
							if filter then
								new = filter(self, new, ...)
								if not new then return end -- filtered out
							end
							s.parentCache[s.lastKey] = new
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
	end,

	--- Disable the input and its children, preventing further updates and events.
	-- The input can be reenabled using `enable`.
	disable = function(self)
		if self.enabled then
			for _, c in ipairs(self.children) do
				c:disable()
			end
			self._event:pause()
			self.enabled = false
		end
	end,
	--- Enable the input and its children, allowing further updates and events.
	-- The should be called after disabling the input using `disable`.
	enable = function(self)
		if not self.enabled then
			self.enabled = true
			self._event:resume()
			for _, c in ipairs(self.children) do
				c:enable()
			end
		end
	end,

	--- Will call `fn(source)` on the next activated source (including sources not currently used by this input).
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
			if abs(new) >= self._threshold then
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
	-- To stop grabbing an input, you will need to `release` the subinput.
	--
	-- This will also reset the input to a neutral state. The subinput will share everything with this input, except
	-- `grabbed`, `grabbing`, `event` (a new event registry is created), and of course its current state.
	grab = function(self)
		local g = {
			grabbed = false,
			grabbing = self,
			event = signal.new(),
			children = {},
			_value = {},
			_prevValue = {},
		}
		for i=1, self._dimension do
			g._value[i] = self._value[i]
			g._prevValue[i] = self._prevValue[i]
		end
		for _, c in ipairs(self.children) do
			local gc = c:grab()
			table.insert(g.children, gc)
			g.children[c.name] = gc
			g[c.name] = gc
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

	--- Set the state of this input to a neutral position (i.e. value = 0 for every dimension).
	neutralize = function(self)
		local zeros = { 0 }
		for i=2, self._dimension do zeros[i] = 0 end
		self:_update(zeros)
		self._state = "none"
		for i=1, self._dimension do
			self._value[i] = 0
			self._prevValue[i] = 0
		end
	end,

	--- Set the joystick associated with this input.
	-- This input will then ignore every other joystick.
	-- Set joystick to `nil` to disable and get input from every connected joystick.
	-- @param joystick LÖVE jostick object to associate
	setJoystick = function(self, joystick)
		self._joystick = joystick
		for _, i in ipairs(self.children) do
			i:setJoystick(joystick)
		end
	end,
	--- Returns the currently selected joystick.
	-- @treturn joystick LÖVE jostick object
	getJoystick = function(self)
		return self._joystick
	end,

	--- Returns `true` if the input is currently down, `false` otherwise.
	-- @treturn boolean if input is down on at least one dimensions
	down = function(self)
		return self._state == "down" or self._state == "pressed"
	end,
	--- Returns `true` if the input has just been pressed, `false` otherwise.
	-- @treturn boolean if input has just been pressed on at least one dimensions
	pressed = function(self)
		return self._state == "pressed"
	end,
	--- Returns `true` if the input has just been released, `false` otherwise.
	-- @treturn boolean if input has just been released on at least one dimensions
	released = function(self)
		return self._state == "released"
	end,
	--- Returns the current value of the input.
	-- If dimension > 1, this will return several values, one per dimension.
	-- @treturn number,... current value of the input for every dimension
	value = function(self)
		return unpack(self._value)
	end,
	--- Returns the delta value of the input since the last call to `update`.
	-- If dimension > 1, this will return several values, one per dimension.
	-- @treturn number,... delta of the input for every dimension
	delta = function(self)
		for i=1, self._dimension do
			tmp[i] = self._value[i] - self._prevValue[i]
		end
		return unpack(tmp, 1, self._dimension)
	end,

	-- Update the state of the input: called at least on every input value change and on :update().
	-- new: new value of the input if it has changed (list of numbers of size config.dimension, can be anything, but typically in [0-1]) (optional)
	_update = function(self, new)
		if self.grabbed then
			self.grabbed:_update(new) -- pass onto grabber
		else
			local threshold = self._threshold
			-- update values
			new = new or self._value
			local old = self._value
			self._value = new
			-- compute delta (in tmp)
			for i=1, self._dimension do
				tmp[self._dimension + i] = new[i] - old[i]
				tmp[i] = new[i]
			end
			-- update state and emit events
			for i=self._dimension, self._dimension * 2 do
				if tmp[i] ~= 0 then
					self.event:emit("moved", unpack(tmp, 1, self._dimension * 2))
					break
				end
			end
			for i=1, self._dimension do
				if abs(new[i]) >= threshold then
					if abs(old[i]) < threshold then
						self._state = "pressed"
						self.event:emit("pressed", i, unpack(tmp, 1, self._dimension * 2))
					else
						self._state = "down"
					end
				else
					if abs(old[i]) >= threshold then
						self._state = "released"
						self.event:emit("released", i, unpack(tmp, 1, self._dimension * 2))
					else
						self._state = "none"
					end
				end
			end
		end
	end
}
input_mt.__index = input_mt

--- Input sources.
-- Input sources are the initial source of input data; each input source can return a single number value.
-- They are identified by a Lua identifier name.
-- See [expressions](#Input_expressions) on how to use them in expressions.
--
-- Input sources are provided for common input methods (keyboard, mouse, gamepad) by default; see below for a list of built-in input sources.
--
-- Additionally, you can define your own input sources, by emitting events in the SignalRegistry returned by `uqt.input.event`.
-- See the file `input/event.lua` to see a description of the events you will need to emit. The file also contains the definition
-- of the built-in input sources that you may use as an example.
--
-- @section Sources

--- Keyboard input: 1 if the key X is down, 0 otherwise.
-- X can be any of LÖVE's [KeyConstant](https://love2d.org/wiki/KeyConstant).
-- @field key.X

--- Keyboard input: 1 if the key with scancode X is down, 0 otherwise.
-- X can be any of LÖVE's [Scancode](https://love2d.org/wiki/Scancode).
-- @field scancode.X

--- Text input: 1 if the text X was entered, 0 otherwise.
-- X can be any text.
-- @field text.X

--- Mouse input: `mouse[N]` is 1 if the mouse button is down, 0 otherwise.
-- N is either 1 for the primary mouse button, 2 for secondary or 3 for middle button.
-- @field mouse `mouse[N]`

--- Mouse input: X position of the mouse cursor in the game window.
-- @field mouse.x

--- Mouse input: Y position of the mouse cursor in the game window.
-- @field mouse.y

--- Mouse input: latest X movement of the mouse cursor.
--
-- `mouse.dx.p` and `mouse.dx.n` will respectively only report movement in the positive or negative direction and return absolute value.
-- @field mouse.dx

--- Mouse input: latest Y movement of the mouse cursor.
--
-- `mouse.dy.p` and `mouse.dy.n` will respectively only report movement in the positive or negative direction and return absolute value.
-- @field mouse.dy

--- Mouse input: latest X movement of the mouse wheel.
--
-- `wheel.dx.p` and `wheel.dx.n` will respectively only report movement in the positive or negative direction and return absolute value.
-- @field wheel.dx

--- Mouse input: latest Y movement of the mouse wheel.
--
-- `wheel.dy.p` and `wheel.dy.n` will respectively only report movement in the positive or negative direction and return absolute value.
-- @field wheel.dy

--- Gamepad input: 1 if the button X is down, 0 otherwise.
-- X can be any of LÖVE's [GamepadButton](https://love2d.org/wiki/GamepadButton).
-- @field button.X

--- Gamepad input: current value of the gamepad axis (between -1 and 1).
-- X can be any of LÖVE's [GamepadAxis](https://love2d.org/wiki/GamepadAxis).
--
-- `axis.X.p` and `axis.X.n` will respectively only report movement in the positive or negative direction and return absolute value.
-- @field axis.X

--- On new frame: current delta time value since last frame. Updated on each call to `love.update`.
-- Note that if this input source is present in an expression, the other input sources in the same expression will be set as passive by default.
-- @field dt

--- Children inputs: current value of a child input of the current input.
-- For child inputs of dimension 1.
-- Replace X with the name of the child input.
--
-- If the child input is of dimension at least 2, instead use `child.X[N]`, which gives the
-- current value of the Nth dimension of a child input of the current input.
-- Replace X with the name of the child input, and N with the index of the dimension you want.
-- @field child.X

--- Current input: current value of the current input.
-- For inputs of dimension 1.
--
-- If the input is of dimension at least 2, instead use `value[N]`, which gives the
-- current value of the Nth dimension of the current input.
-- Replace N with the index of the dimension you want.
--
-- Note that is input is passive by default.
-- Think twice before marking it active as this may create a feedback loop (the input being updated will trigger it to be updated again, and so on).
-- @field value

return make_input
