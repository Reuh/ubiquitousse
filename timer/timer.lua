--- ubiquitousse.timer
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
	-- @tparam number dt the delta-time (time spent since last time the function was called) (miliseconds)
	-- @impl ubiquitousse
	update = function(self, dt)
		self.dt = dt

		local done = {} -- functions done running

		local d = self.delayed
		for func, t in pairs(d) do
			if t and all(t.initWhen, true) then
				t.initWhen = {}
				local co = t.coroutine
				-- skip
				dt = self.dt
				if t.skip then dt = dt + t.skip end
				-- start
				if t.after then t.after = t.after - dt end
				if t.forceStart or ((not t.after or t.after <= 0) and all(t.startWhen, true)) then
					local startLag = 0
					if t.after then
						startLag = -t.after
					elseif t.skip then
						startLag = t.skip
					end
					t.after, t.skip = nil, nil
					t.startWhen = {}
					d[func] = false -- niling here cause the next pair iteration to error
					table.insert(done, func)
					if not co then
						co = coroutine.create(func)
						t.coroutine = co
						if t.times > 0 then t.times = t.times - 1 end
						for _, f in ipairs(t.onStart) do f(t.object, startLag) end
					end
					-- update
					assert(coroutine.resume(co, function(delay)
						t.after = delay - startLag
						d[func] = t
						coroutine.yield()
					end, dt))
					for _, f in ipairs(t.onUpdate) do f(t.object, startLag) end
					if t.during then t.during = t.during - startLag - dt end
					-- stopping / repeat
					if all(t.stopWhen, false) then t.forceStop = true end
					if t.forceStop or coroutine.status(co) == "dead" then
						if t.forceStop
							or (t.during and t.during <= 0)
							or (t.times == 0)
							or (not all(t.repeatWhile, true))
							or (t.every == nil and t.times == -1 and t.during == nil and #t.repeatWhile == 0) -- no repeat
						then
							local endLag = t.during and -t.during or 0
							for _, f in ipairs(t.onEnd) do f(t.object, endLag) end
						else
							if t.times > 0 then t.times = t.times - 1 end
							if t.every then t.after = t.every - startLag end
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
	-- As a third parameter, the function will receive the lag time (difference between the time when the function was run and when it should have been run).
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

			after = nil,
			every = nil,
			times = -1,
			during = nil,

			initWhen = {},
			startWhen = {},
			repeatWhile = {},
			stopWhen = {},

			forceStart = false,
			forceStop = false,
			skip = nil,

			onStart = {},
			onUpdate = {},
			onEnd = {}
		}

		local t = self.delayed[func] -- internal data
		local r -- external interface
		r = {
			--- Timed conditions ---
			--- Wait time milliseconds before running the function.
			-- Specify no time to remove condition.
			after = function(_, time)
				t.after = time
				return r
			end,
			--- Run the function every time millisecond.
			-- Specify no time to remove condition.
			every = function(_, time)
				t.every = time
				return r
			end,
			--- The function will not execute more than count times.
			-- Specify no time to remove condition.
			times = function(_, count)
				t.times = count or -1
				return r
			end,
			--- The TimedFunction will be active for a time duration.
			-- Specify no time to remove condition.
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
			--- Skip some amount of time.
			skip = function(_, time)
				t.skip = (t.skip or 0) + time
			end,

			--- Callbacks functions ---
			--- Will execute func(self, lag) when the function execution start.
			onStart = function(_, func)
				table.insert(t.onStart, func)
				return r
			end,
			--- Will execute func(self, lag) each frame the main function is run.
			onUpdate = function(_, func)
				table.insert(t.onUpdate, func)
				return r
			end,
			--- Will execute func(self, lag) when the function execution end.
			onEnd = function(_, func)
				table.insert(t.onEnd, func)
				return r
			end,

			--- Chaining ---
			--- Creates another TimedFunction which will be initialized immediately when the current one ends.
			-- Returns the new TimedFunction.
			chain = function(_, func)
				local done = false
				local fn = self:run(func)
					:initWhen(function() return done end)
				r:onEnd(function(self, lag)
					done = true
					fn:skip(lag)
				end)
				return fn
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
			local fn = self:tween(duration_, tbl_, to_, method_)
				:initWhen(function() return done end)
			r:onEnd(function(self, lag)
				done = true
				fn:skip(lag)
			end)
			return fn
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

			--- Time since last timer update (miliseconds).
			dt = 0
		}, registry_mt)
	end,

	--- Time since last update (miliseconds).
	-- @impl ubiquitousse
	dt = 0,

	--- Global TimerRegistry.
	-- @impl ubiquitousse
	delayed = {},
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
