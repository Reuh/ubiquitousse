--- ubiquitousse.timer
local ease = require((...):match("^.-timer")..".easing")

local timer_module

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

-- Timer methods.
local timer_mt = {
	--- timer data table
	t = nil,

	--- Wait time milliseconds before running the function.
	-- Specify no time to remove condition.
	after = function(self, time)
		self.t.after = time
		return self
	end,
	--- Run the function every time millisecond.
	-- Specify no time to remove condition.
	every = function(self, time)
		self.t.every = time
		return self
	end,
	--- The function will not execute more than count times.
	-- Specify no time to remove condition.
	times = function(self, count)
		self.t.times = count or -1
		return self
	end,
	--- The TimedFunction will be active for a time duration.
	-- Specify no time to remove condition.
	during = function(self, time)
		self.t.during = time
		return self
	end,

	--- Function conditions ---
	--- Starts the function execution when func() returns true. Checked before the "after" condition,
	-- meaning the "after" countdown starts when func() returns true.
	-- If multiple init functions are added, init will trigger only when all of them returns true.
	initWhen = function(self, func)
		table.insert(self.t.initWhen, func)
		return self
	end,
	--- Starts the function execution when func() returns true. Checked after the "after" condition.
	-- If multiple start functions are added, start will trigger only when all of them returns true.
	startWhen = function(self, func)
		table.insert(self.t.startWhen, func)
		return self
	end,
	--- When the functions ends, the execution won't stop and will repeat as long as func() returns true.
	-- Will cancel timed repeat conditions if false but needs other timed repeat conditions to be true to create a new repeat.
	-- If multiple repeat functions are added, a repeat will trigger only when all of them returns true.
	repeatWhile = function(self, func)
		table.insert(self.t.repeatWhile, func)
		return self
	end,
	--- Stops the function execution when func() returns true. Checked before all timed conditions.
	-- If multiple stop functions are added, stop will trigger only when all of them returns true.
	stopWhen = function(self, func)
		table.insert(self.t.stopWhen, func)
		return self
	end,

	--- Conditions override ---
	--- Force the function to start its execution.
	start = function(self)
		self.t.forceStart = true
		return self
	end,
	--- Force the function to stop its execution.
	stop = function(self)
		self.t.forceStop = true
		return self
	end,
	--- Force the function to stop immediately. Won't trigger onEnd or other callbacks.
	abort = function(self)
		self.t.abort = true
		return self
	end,
	--- Skip some amount of time.
	skip = function(self, time)
		self.t.skip = (self.t.skip or 0) + time
	end,

	--- Callbacks functions ---
	--- Will execute func(self, lag) when the function execution start.
	onStart = function(self, func)
		table.insert(self.t.onStart, func)
		return self
	end,
	--- Will execute func(self, lag) each frame the main function is run.
	onUpdate = function(self, func)
		table.insert(self.t.onUpdate, func)
		return self
	end,
	--- Will execute func(self, lag) when the function execution end.
	onEnd = function(self, func)
		table.insert(self.t.onEnd, func)
		return self
	end,

	--- Chaining ---
	--- Creates another TimedFunction which will be replace the current one when it ends.
	-- Returns the new TimedFunction.
	chain = function(self, func)
		local fn = timer_module.run(func)
		self:onEnd(function(self, lag)
			fn:skip(lag)
			self.t = fn.t
		end)
		return fn
	end,

	--- Management ---
	--- Update the timer.
	-- Should be called at every game update.
	-- @tparam number dt the delta-time (time spent since last time the function was called) (miliseconds)
	-- @impl ubiquitousse
	update = function(self, dt)
		local t = self.t
		if not t.dead then
			if t.abort then
				t.dead = true
			elseif all(t.initWhen, true) then
				t.initWhen = {}
				local co = t.coroutine
				-- skip
				local cdt = dt
				if t.skip then cdt = cdt + t.skip end
				-- start
				if t.after then t.after = t.after - cdt end
				if t.forceStart or ((not t.after or t.after <= 0) and all(t.startWhen, true)) then
					local startLag = 0
					if t.after then
						startLag = -t.after
					elseif t.skip then
						startLag = t.skip
					end
					t.after, t.skip = nil, nil
					t.startWhen = {}
					t.dead = true -- niling here cause the next pair iteration to error
					if not co then
						co = coroutine.create(t.func)
						t.coroutine = co
						if t.times > 0 then t.times = t.times - 1 end
						for _, f in ipairs(t.onStart) do f(self, startLag) end
					end
					-- update
					assert(coroutine.resume(co, self, cdt, 0, function(delay)
						t.after = delay - startLag
						t.dead = false
						local _, _, cdt, lag = coroutine.yield()
						return cdt, lag
					end))
					for _, f in ipairs(t.onUpdate) do f(t.object, startLag) end
					if t.during then t.during = t.during - startLag - cdt end
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
							for _, f in ipairs(t.onEnd) do f(self, endLag) end
						else
							if t.times > 0 then t.times = t.times - 1 end
							if t.every then t.after = t.every - startLag end
							t.coroutine = coroutine.create(t.func)
							t.dead = false
						end
					end
				end
			end
		end
	end,

	--- Check if the timer is dead.
	-- You shouldn't need to worry about this if your timer belongs to a registry?
	-- If you don't use registries, you probably should purge dead timers to free up some memory (dead timers don't do anything otherwise).
	-- @treturn bool true if the timer can be discarded, false if it's still active.
	-- @impl ubiquitousse
	dead = function(self)
		return self.t.dead
	end
}
timer_mt.__index = timer_mt

--- Registry methods.
local registry_mt = {
	--- Update all the timers in the registry.
	-- Should be called at every game update; called by ubiquitousse.update.
	-- @tparam number dt the delta-time (time spent since last time the function was called) (miliseconds)
	-- @impl ubiquitousse
	update = function(self, dt)
		-- process timers
		for _, timer in ipairs(self.timers) do
			timer:update(dt)
		end

		-- remove dead timers
		for i=#self.timers, 1, -1 do
			if self.timers[i]:dead() then
				table.remove(self.timers, i)
			end
		end
	end,

	--- Create a new timer and add it to the registry.
	-- Same as timer_module.run, but add it to the registry.
	-- @impl ubiquitousse
	run = function(self, func)
		local r = timer_module.run(func)
		table.insert(self.timers, r)
		return r
	end,

	--- Create a new tween timer and add it to the registry.
	-- Same as timer_module.tween, but add it to the registry.
	-- @impl ubiquitousse
	tween = function(self, duration, tbl, to, method)
		local r = timer_module.tween(duration, tbl, to, method)
		table.insert(self.timers, r)
		return r
	end,

	--- Cancels all the running TimedFunctions.
	-- @impl ubiquitousse
	clear = function(self)
		self.timers = {}
	end
}
registry_mt.__index = registry_mt

--- Time related functions
timer_module = {
	--- Creates and return a new timer registry.
	-- A timer registry provides an easy way to handle your timers; it will keep track of them,
	-- updating and removing them as needed. If you use the scene system, a scene-specific
	-- timer registry is available at ubiquitousse.scene.current.timer.
	-- @impl ubiquitousse
	new = function()
		return setmetatable({
			--- Used to store all the functions delayed with ubiquitousse.time.delay
			-- The default implementation use the structure {<key: function> = <value: data table>, ...}
			-- This table is for internal use and shouldn't be used from an external script.
			timers = {}
		}, registry_mt)
	end,

	--- Create a new timer that will run a function.
	-- The function will receive as first parameter the timer object.
	-- As a second parameter, the function will receive the delta time (dt).
	-- As a third parameter, the function will receive the lag time (difference between the time when the function was run and when it should have been run).
	-- As a fourth parameter, the function will receive as first parameter the wait(time) function, which will pause the function execution for time miliseconds.
	-- You will need to call the :update(dt) method on the timer object every frame to make it do something, or create the timer from a timer registry if you
	-- don't want to handle your timers manually.
	-- @tparam[opt] function func the function to schedule
	-- @treturn timer the object
	-- @impl ubiquitousse
	run = function(func)
		local r = setmetatable({
			t = {
				dead = false,
				func = func or function() end,
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
		}, timer_mt)

		return r
	end,

	--- Create a timer that will tween some numeric values.
	-- You will need to call the :update(dt) method on the timer object every frame to make it do something, or create the timer from a timer registry if you
	-- don't want to handle your timers manually.
	-- @tparam number duration tween duration (miliseconds)
	-- @tparam table tbl the table containing the values to tween
	-- @tparam table to the new values
	-- @tparam[opt="linear"] string/function method tweening method (string name or the actual function(time, start, change, duration))
	-- @treturn timer the object. A duration is already defined, and the :chain methods takes the same arguments as tween (and creates a tween).
	-- @impl ubiquitousse
	tween = function(duration, tbl, to, method)
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

		local r = timer_module.run(function(self, dt)
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

			local fn = timer_module.tween(duration_, tbl_, to_, method_)
			r:onEnd(function(self, lag)
				fn:skip(lag)
				self.t = fn.t
			end)
			return fn
		end

		return r
	end
}

return timer_module
