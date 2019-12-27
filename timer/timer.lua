--- ubiquitousse.timer
-- Depends on a backend.
-- Optional dependencies: ubiquitousse.signal (to bind to update signal in signal.event)
local loaded, signal = pcall(require, (...):match("^(.-)timer").."signal")
if not loaded then signal = nil end

local ease = require((...):match("^.-timer")..".easing")
local timer

--- Returns true if all the values in the list are true ; functions in the list will be called and the test will be performed on their return value.
-- Returns default if the list is empty.
local function all(list, default)
	if #list == 0 then
		return default
	else
		local r = true
		for _,v in ipairs(list) do
			if type(v) == "function" then
				r = r and v()
			else
				r = r and v
			end
		end
		return r
	end
end

--- Registry methods.
local registry_mt = {
	--- Update all the TimedFunctions calls.
	-- Should be called at every game update; called by ubiquitousse.update.
	-- @tparam[opt=calculate here] number dt the delta-time (time spent since last time the function was called) (miliseconds)
	-- @impl ubiquitousse
	update = function(self, dt)
		local currentTime = timer.get()

		if not dt then
			dt = currentTime - self.lastTime
			self.lastTime = currentTime
		end
		self.dt = dt

		local done = {} -- functions done running

		local d = self.delayed
		for func, t in pairs(d) do
			if t and all(t.initWhen, true) then
				t.initWhen = {}
				local co = t.coroutine
				t.after = t.after - dt
				if t.forceStart or (t.after <= 0 and all(t.startWhen, true)) then
					t.startWhen = {}
					d[func] = false -- niling here cause the next pair iteration to error
					table.insert(done, func)
					if not co then
						co = coroutine.create(func)
						t.coroutine = co
						t.started = currentTime
						if t.times > 0 then t.times = t.times - 1 end
						for _, f in ipairs(t.onStart) do f(t.object) end
					end
					assert(coroutine.resume(co, function(delay)
						t.after = delay or 0
						d[func] = t
						coroutine.yield()
					end, dt))
					for _, f in ipairs(t.onUpdate) do f(t.object) end
					if all(t.stopWhen, false) then t.forceStop = true end
					if t.forceStop or coroutine.status(co) == "dead" then
						if t.forceStop
							or (t.during >= 0 and t.started + t.during < currentTime)
							or (t.times == 0)
							or (not all(t.repeatWhile, true))
							or (t.every == -1 and t.times == -1 and t.during == -1 and #t.repeatWhile == 0) -- no repeat
						then
							for _, f in ipairs(t.onEnd) do f(t.object) end
						else
							if t.times > 0 then t.times = t.times - 1 end
							t.after = t.every
							t.coroutine = coroutine.create(func)
							d[func] = t
						end
					end
				end
			end
		end

		for _, func in ipairs(done) do
			if not d[func] then
				d[func] = nil
			end
		end
	end,

	--- Schedule a function to run.
	-- The function will receive as first parameter the wait(time) function, which will pause the function execution for time miliseconds.
	-- As a second parameter, the function will receive the delta time (dt).
	-- @tparam[opt] function func the function to schedule
	-- @treturn TimedFunction the object
	-- @impl ubiquitousse
	run = function(self, func)
		-- Creates empty function (the TimedFunction may be used for time measure or stuff like that which doesn't need a specific function)
		func = func or function() end

		-- Since delayed functions can end in any order, it doesn't really make sense to use a integer-keyed list.
		-- Using the function as the key works and it's unique.
		self.delayed[func] = {
			object = nil,
			coroutine = nil,
			started = 0,

			after = -1,
			every = -1,
			times = -1,
			during = -1,

			initWhen = {},
			startWhen = {},
			repeatWhile = {},
			stopWhen = {},

			forceStart = false,
			forceStop = false,

			onStart = {},
			onUpdate = {},
			onEnd = {}
		}

		local t = self.delayed[func] -- internal data
		local r -- external interface
		r = {
			--- Timed conditions ---
			--- Wait time milliseconds before running the function.
			after = function(_, time)
				t.after = time
				return r
			end,
			--- Run the function every time millisecond.
			every = function(_, time)
				t.every = time
				return r
			end,
			--- The function will not execute more than count times.
			times = function(_, count)
				t.times = count
				return r
			end,
			--- The TimedFunction will be active for a time duration.
			during = function(_, time)
				t.during = time
				return r
			end,

			--- Function conditions ---
			--- Starts the function execution when func() returns true. Checked before the "after" condition,
			-- meaning the "after" countdown starts when func() returns true.
			-- If multiple init functions are added, init will trigger only when all of them returns true.
			initWhen = function(_, func)
				table.insert(t.initWhen, func)
				return r
			end,
			--- Starts the function execution when func() returns true. Checked after the "after" condition.
			-- If multiple start functions are added, start will trigger only when all of them returns true.
			startWhen = function(_, func)
				table.insert(t.startWhen, func)
				return r
			end,
			--- When the functions ends, the execution won't stop and will repeat as long as func() returns true.
			-- Will cancel timed repeat conditions if false but needs other timed repeat conditions to be true to create a new repeat.
			-- If multiple repeat functions are added, a repeat will trigger only when all of them returns true.
			repeatWhile = function(_, func)
				table.insert(t.repeatWhile, func)
				return r
			end,
			--- Stops the function execution when func() returns true. Checked before all timed conditions.
			-- If multiple stop functions are added, stop will trigger only when all of them returns true.
			stopWhen = function(_, func)
				table.insert(t.stopWhen, func)
				return r
			end,

			--- Conditions override ---
			--- Force the function to start its execution.
			start = function(_)
				t.forceStart = true
				return r
			end,
			--- Force the function to stop its execution.
			stop = function(_)
				t.forceStop = true
				return r
			end,

			--- Callbacks functions ---
			--- Will execute func(self) when the function execution start.
			onStart = function(_, func)
				table.insert(t.onStart, func)
				return r
			end,
			--- Will execute func(self) each frame the main function is run.
			onUpdate = function(_, func)
				table.insert(t.onUpdate, func)
				return r
			end,
			--- Will execute func(self) when the function execution end.
			onEnd = function(_, func)
				table.insert(t.onEnd, func)
				return r
			end,

			--- Chaining ---
			--- Creates another TimedFunction which will be initialized when the current one ends.
			-- Returns the new TimedFunction.
			chain = function(_, func)
				local done = false
				r:onEnd(function() done = true end)
				return self:run(func)
					:initWhen(function() return done end)
			end
		}
		t.object = r
		return r
	end,

	--- Tween some numeric values.
	-- @tparam number duration tween duration (miliseconds)
	-- @tparam table tbl the table containing the values to tween
	-- @tparam table to the new values
	-- @tparam[opt="linear"] string/function method tweening method (string name or the actual function(time, start, change, duration))
	-- @treturn TimedFunction the object. A duration is already defined, and the :chain methods takes the same arguments as tween (and creates a tween).
	-- @impl ubiquitousse
	tween = function(self, duration, tbl, to, method)
		method = method or "linear"
		method = type(method) == "string" and ease[method] or method

		local time = 0 -- tweening time elapsed
		local from = {} -- initial state

		local function update(tbl_, from_, to_) -- apply the method to tbl_ recursively (doesn't handle cycles)
			for k, v in pairs(to_) do
				if type(v) == "table" then
					update(tbl_[k], from_[k], to_[k])
				else
					if time < duration then
						tbl_[k] = method(time, from_[k], v - from_[k], duration)
					else
						tbl_[k] = v
					end
				end
			end
		end

		local r = self:run(function(wait, dt)
			time = time + dt
			update(tbl, from, to)
		end):during(duration)
		    :onStart(function()
				local function copy(stencil, source, dest) -- copy initial state recursively
					for k, v in pairs(stencil) do
						if type(v) == "table" then
							if not dest[k] then dest[k] = {} end
							copy(stencil[k], source[k], dest[k])
						else
							dest[k] = source[k]
						end
					end
				end
				copy(to, tbl, from)
			end)

		--- Creates another tween which will be initialized when the current one ends.
		-- If tbl_ and/or method_ are not specified, the values from the current tween will be used.
		-- Returns the new tween.
		r.chain = function(_, duration_, tbl_, to_, method_)
			if not method_ and to_ then
				if type(to_) == "string" then
					tbl_, to_, method_ = tbl, tbl_, to_
				else
					method_ = method
				end
			elseif not method_ and not to_ then
				tbl_, to_, method_ = tbl, tbl_, method
			end

			local done = false
			r:onEnd(function() done = true end)
			return self:tween(duration_, tbl_, to_, method_)
				:initWhen(function() return done end)
		end

		return r
	end,

	--- Cancels all the running TimedFunctions.
	-- @impl ubiquitousse
	clear = function(self)
		self.delayed = {}
	end
}
registry_mt.__index = registry_mt

--- Time related functions
timer = {
	--- Creates and return a new TimerRegistry.
	-- A TimerRegistry is a separate ubiquitousse.time instance: its TimedFunctions will be independant
	-- from the one registered using ubiquitousse.time.run (the global TimerRegistry). If you use the scene
	-- system, a scene-specific TimerRegistry is available at ubiquitousse.scene.current.time.
	-- @impl ubiquitousse
	new = function()
		return setmetatable({
			--- Used to store all the functions delayed with ubiquitousse.time.delay
			-- The default implementation use the structure {<key: function> = <value: data table>, ...}
			-- This table is for internal use and shouldn't be used from an external script.
			delayed = {},

			-- Used to calculate the deltatime
			lastTime = timer.get(),

			--- Time since last timer update (miliseconds).
			dt = 0
		}, registry_mt)
	end,

	--- Returns the number of miliseconds elapsed since some point in time.
	-- This point is fixed but undetermined, so this function should only be used to calculate durations.
	-- Should at least have millisecond-precision, but can be more precise if available.
	-- @impl backend
	get = function() end,

	--- Time since last update (miliseconds).
	-- @impl ubiquitousse
	dt = 0,

	--- Global TimerRegistry.
	-- @impl ubiquitousse
	delayed = {},
	lastTime = 0,
	update = function(...) -- If ubiquitousse.signal is available, will be bound to the "update" signal in signal.event.
		return registry_mt.update(timer, ...)
	end,
	run = function(...)
		return registry_mt.run(timer, ...)
	end,
	tween = function(...)
		return registry_mt.tween(timer, ...)
	end,
	clear = function(...)
		return registry_mt.clear(timer, ...)
	end
}

-- Bind signals
if signal then
	signal.event:bind("update", timer.update)
end

return timer
