--- Scene management.
--
-- You can use use scenes to seperate the different states of your game: for example, a menu scene and a game scene.
-- This module is fully implemented in Ubiquitousse and is mostly a "recommended way" of organising an Ubiquitousse-based game.
-- However, you don't have to use this if you don't want to. ubiquitousse.scene handles all the differents Ubiquitousse-states and
-- make them scene-independent, for example by creating a scene-specific TimerRegistry (TimedFunctions that are keept accross
-- states are generally a bad idea). Theses scene-specific states should be created and available in the table returned by
-- ubiquitousse.scene.new.
--
-- The expected code-organisation is:
--
-- * each scene is in a file, identified by its module name (scenes will be loaded using require("modulename"))
-- * each scene file create a new scene table using ubiquitousse.scene.new and returns it at the end of the file
--
-- Order of callbacks:
--
-- * all scene change callbacks are called after setting scene.current to the new scene but before changing scene.stack
-- * all scene exit/suspend callbacks are called before scene enter/resume callbacks
--
-- No mendatory dependency.
-- Optional dependencies:
--
-- * ubiquitousse.timer (to provide each scene a timer registry).
-- * ubiquitousse.signal (to bind to update and draw signal in signal.event).
-- @module scene
local loaded, signal = pcall(require, (...):match("^(.-)scene").."signal")
if not loaded then signal = nil end
local loaded, timer = pcall(require, (...):match("^(.-)scene").."timer")
if not loaded then timer = nil end

--- Scene object.
-- @type Scene
local _ = {
	--- The scene name.
	name = name or "unamed",
	--- Scene-specific TimerRegistry, if uqt.time is available.
	timer = timer and timer.new(),
	--- Scene-specific SignalRegistry, if uqt.signal is available.
	signal = signal and signal.new(),
	--- Called when entering a scene.
	-- @callback
	enter = function(self, ...) end,
	--- Called when exiting a scene, and not expecting to come back (scene may be unloaded).
	-- @callback
	exit = function(self) end,
	--- Called when suspending a scene, and expecting to come back (scene won't be unloaded).
	-- @callback
	suspend = function(self) end,
	--- Called when resuming a suspended scene (after calling suspend).
	-- @callback
	resume = function(self) end,
	--- Called on each update on the current scene.
	-- @callback
	update = function(self, dt, ...) end,
	--- Called on each draw on the current scene.
	-- @callback
	draw = function(self, ...) end
}

--- Module.
-- @section module

local scene
scene = {
	--- The current scene object.
	current = nil,

	--- Shortcut for scene.current.timer.
	timer = nil,
	--- Shortcut for scene.current.signal.
	signal = nil,

	--- The scene stack: list of scene, from the farest one to the nearest.
	stack = {},

	--- A prefix for scene modules names.
	-- Will search in the "scene" directory by default (`prefix="scene."`). Redefine it to fit your own ridiculous filesystem.
	prefix = "scene.",

	--- Creates and returns a new Scene object.
	-- @tparam[opt="unamed"] string name the new scene name
	-- @treturn Scene
	new = function(name)
		return {
			name = name or "unamed",
			timer = timer and timer.new(),
			signal = signal and signal.new(),
			enter = function(self, ...) end,
			exit = function(self) end,
			suspend = function(self) end,
			resume = function(self) end,
			update = function(self, dt, ...) end,
			draw = function(self, ...) end
		}
	end,

	--- Switch to a new scene.
	-- The new scene will be required() and the current scene will be replaced by the new one,
	-- then the previous scene exit function will be called, then the enter callback is called on the new scence.
	-- Then the stack is changed to replace the old scene with the new one.
	-- @tparam string/table scenePath the new scene module name, or the scene table directly
	-- @param ... arguments to pass to the scene's enter function
	switch = function(scenePath, ...)
		local previous = scene.current
		scene.current = type(scenePath) == "string" and require(scene.prefix..scenePath) or scenePath
		scene.timer = scene.current.timer
		scene.signal = scene.current.signal
		scene.current.name = scene.current.name or tostring(scenePath)
		if previous then
			previous:exit()
			if timer then previous.timer:clear() end
		end
		scene.current:enter(...)
		scene.stack[math.max(#scene.stack, 1)] = scene.current
	end,

	--- Push a new scene to the scene stack.
	-- Similar to ubiquitousse.scene.switch, except suspend is called on the current scene instead of exit,
	-- and the current scene is not replaced: when the new scene call ubiquitousse.scene.pop, the old scene
	-- will be reused.
	-- @tparam string/table scenePath the new scene module name, or the scene table directly
	-- @param ... arguments to pass to the scene's enter function
	push = function(scenePath, ...)
		local previous = scene.current
		scene.current = type(scenePath) == "string" and require(scene.prefix..scenePath) or scenePath
		scene.timer = scene.current.timer
		scene.signal = scene.current.signal
		scene.current.name = scene.current.name or tostring(scenePath)
		if previous then previous:suspend() end
		scene.current:enter(...)
		table.insert(scene.stack, scene.current)
	end,

	--- Pop the current scene from the scene stack.
	-- The previous scene will be set as the current scene, then the current scene exit function will be called,
	-- then the previous scene resume function will be called, and then the current scene will be removed from the stack.
	pop = function()
		local previous = scene.current
		scene.current = scene.stack[#scene.stack-1]
		scene.timer = scene.current and scene.current.timer or nil
		scene.signal = scene.current and scene.current.signal or nil
		if previous then
			previous:exit()
			if timer then previous.timer:clear() end
		end
		if scene.current then scene.current:resume() end
		table.remove(scene.stack)
	end,

	--- Pop all scenes.
	popAll = function()
		while scene.current do
			scene.pop()
		end
	end,

	--- Update the current scene.
	-- Should be called at every game update. If ubiquitousse.signal is available, will be bound to the "update" signal in signal.event.
	-- @tparam number dt the delta-time (milisecond)
	-- @param ... arguments to pass to the scene's update function after dt
	update = function(dt, ...)
		if scene.current then
			if timer then scene.current.timer:update(dt) end
			scene.current:update(dt, ...)
		end
	end,

	--- Draw the current scene.
	-- Should be called every time the game is draw. If ubiquitousse.signal is available, will be bound to the "draw" signal in signal.event.
	-- @param ... arguments to pass to the scene's draw function
	draw = function(...)
		if scene.current then scene.current:draw(...) end
	end
}

-- Bind signals
if signal then
	signal.event:bind("update", scene.update)
	signal.event:bind("draw", scene.draw)
end

return scene
