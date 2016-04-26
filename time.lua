-- abstract.time
local ease = require((...):match("^(.-abstract)%.")..".lib.easing")

--- Time related functions
local function newTimerRegistry()
	--- Used to store all the functions delayed with abstract.time.delay
	-- The default implementation use the structure {<key: function> = <value: data table>, ...}
	-- This table is for internal use and shouldn't be used from an external script.
	local delayed = {}

	-- Used to calculate the deltatime
	local lastTime

	local registry
	registry = {
		--- Creates and return a new TimerRegistry.
		-- A TimerRegistry is a separate abstract.time instance: its TimedFunctions will be independant
		-- from the one registered using abstract.time.run (the global TimerRegistry). If you use the scene
		-- system, a scene-specific TimerRegistry is available at abstract.scene.current.time.
		new = function()
			local new = newTimerRegistry()
			new.get = registry.get
			return new
		end,

		--- Returns the number of seconds elapsed since some point in time.
		-- This point is fixed but undetermined, so this function should only be used to calculate durations.
		-- Should at least have millisecond-precision. Should be called using abstract.time.get and not in
		-- non-global TimerRegistry.
		-- @impl backend
		get = function() end,

		--- Update all the TimedFunctions calls.
		-- Supposed to be called in abstract.event.update.
		-- @tparam[opt=calculate here] numder dt the delta-time (time spent since last time the function was called) (seconds)
		-- @impl abstract
		update = function(dt)
			if dt then
				registry.dt = dt
			else
				if lastTime then
					local newTime = registry.get()
					registry.dt = newTime - lastTime
					lastTime = newTime
				else
					lastTime = registry.get()
				end
			end

			local d = delayed
			for func, t in pairs(d) do
				local co = t.coroutine
				t.after = t.after - dt
				if t.after <= 0 then
					d[func] = nil
					if not co then
						co = coroutine.create(func)
						t.coroutine = co
						t.started = registry.get()
						if t.times > 0 then t.times = t.times - 1 end
						t.onStart()
					end
					assert(coroutine.resume(co, function(delay)
						t.after = delay
						d[func] = t
						coroutine.yield()
					end, dt))
					if coroutine.status(co) == "dead" then
						if (t.during >= 0 and t.started + t.during < registry.get())
							or (t.times == 0)
							or (t.every == -1 and t.times == -1 and t.during == -1) -- no repeat
						then
							t.onEnd()
						else
							if t.times > 0 then t.times = t.times - 1 end
							t.after = t.every
							t.coroutine = coroutine.create(func)
							d[func] = t
						end
					end
				end
			end
		end,

		--- Schedule a function to run.
		-- The function will receive as first parameter the wait(time) function, which will pause the function execution for time seconds.
		-- The second parameter is the delta-time.
		-- @tparam[opt=0] number delay delay in seconds before first run
		-- @tparam[opt] function func the function to schedule
		-- @treturn TimedFunction the object
		-- @impl abstract
		run = function(func)
			-- Creates empty function (the TimedFunction may be used for time measure or stuff like that which doesn't need a specific function)
			local func = func or function() end

			-- Since delayed functions can end in any order, it doesn't really make sense to use a integer-keyed list.
			-- Using the function as the key works and it's unique.
			delayed[func] = {
				coroutine = nil,
				started = 0,

				after = -1,
				every = -1,
				times = -1,
				during = -1,

				onStart = function() end,
				onEnd = function() end
			}

			local t = delayed[func] -- internal data
			local r -- external interface
			r = {
				after = function(_, time)
					t.after = time
					return r
				end,
				every = function(_, time)
					t.every = time
					return r
				end,
				times = function(_, count)
					t.times = count
					return r
				end,
				during = function(_, time)
					t.during = time
					return r
				end,

				onStart = function(_, func)
					t.onStart = func
					return r
				end,
				onEnd = function(_, func)
					t.onEnd = func
					return r
				end
			}
			return r
		end,

		--- Tween some numeric values.
		-- @tparam number duration tween duration (seconds)
		-- @tparam table tbl the table containing the values to tween
		-- @tparam table to the new values
		-- @tparam[opt="linear"] string/function method tweening method (string name or the actual function(time, start, change, duration))
		-- @treturn TimedFunction the object
		-- @impl abstract
		tween = function(duration, tbl, to, method)
			local method = method or "linear"
			method = type(method) == "string" and ease[method] or method

			local time = 0
			local from = {}
			for k in pairs(to) do from[k] = tbl[k] end

			return registry.run(function(wait, dt)
				time = time + dt
				for k, v in pairs(to) do
					tbl[k] = method(time, from[k], to[k] - from[k], duration)
				end
			end):during(duration)
		end,

		--- Cancels all the running TimedFunctions.
		-- @impl abstract
		clear = function()
			delayed = {}
		end,

		--- Time since last update (seconds).
		-- @impl abstract
		dt = 0
	}

	return registry
end

return newTimerRegistry()
