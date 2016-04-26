-- abstract.scene
local abstract = require((...):match("^(.-abstract)%."))
local time = abstract.time

--- Returns the file path of the given module name.
local function getPath(modname)
	local filepath = ""
	for path in package.path:gmatch("[^;]+") do
		local path = path:gsub("%?", (modname:gsub("%.", "/")))
		local f = io.open(path)
		if f then f:close() filepath = path break end
	end
	return filepath
end

--- Scene management.
-- You can use use scenes to seperate the different states of your game: for example, a menu scene and a game scene.
-- This module is fully implemented in abstract and is mostly a "recommended way" of organising an abstract-based game.
-- However, you don't have to use this if you don't want to. abstract.scene handles all the differents abstract-states and
-- make them scene-independent, for example by creating a scene-specific TimerRegistry (TimedFunctions that are keept accross
-- states are generally a bad idea). Theses scene-specific states should be created and available in the table returned by
-- abstract.scene.new.
-- The expected code-organisation is:
-- * each scene is in a file, identified by its module name (same identifier used by Lua's require)
-- * each scene file create a new scene table using abstract.scene.new and returns it at the end of the file
-- Order of callbacks:
-- * all scene exit callbacks are called before changing the stack or the current scene (ie, abstract.scene.current and the
--   last stack element is the scene in which the exit or suspend function was called)
-- * all scene enter callbacks are called before changing the stack or the current scene (ie, abstract.scene.current and the
--   last stack element is the previous scene which was just exited, and not the new scene)
local scene
scene = {
	--- The current scene table.
	-- @impl abstract
	current = nil,

	--- The scene stack: list of scene, from the farest one to the nearest.
	-- @impl abstract
	stack = {},

	--- Creates and returns a new Scene object.
	-- @impl abstract
	new = function()
		return {
			time = time.new(), -- Scene-specific TimerRegistry.

			exit = function() end, -- Called when exiting a scene, and not expecting to come back (scene will be unloaded).

			suspend = function() end, -- Called when suspending a scene, and expecting to come back (scene won't be unloaded).
			resume = function() end, -- Called when resuming a suspended scene (after calling suspend).

			update = function(dt) end, -- Called on each abstract.event.update on the current scene.
			draw = function() end -- Called on each abstract.event.draw on the current scene.
		}
	end,

	--- Switch to a new scene.
	-- The current scene exit function will be called, the new scene will be loaded, and then
	-- the current scene will then be replaced by the new one.
	-- @tparam string scenePath the new scene module name
	-- @impl abstract
	switch = function(scenePath)
		if scene.current then scene.current.exit() end
		scene.current = dofile(getPath(scenePath))
		local i = #scene.stack
		scene.stack[math.max(i, 1)] = scene.current
	end,

	--- Push a new scene to the scene stack.
	-- Similar to abstract.scene.switch, except suspend is called on the current scene instead of exit,
	-- and the current scene is not replaced: when the new scene call abstract.scene.pop, the old scene
	-- will be reused.
	-- @tparam string scenePath the new scene module name
	-- @impl abstract
	push = function(scenePath)
		if scene.current then scene.current.suspend() end
		scene.current = dofile(getPath(scenePath))
		table.insert(scene.stack, scene.current)
	end,

	--- Pop the current scene from the scene stack.
	-- The current scene exit function will be called, then the previous scene resume function will be called.
	-- Then the current scene will be removed from the stack, and the previous scene will be set as the current scene.
	-- @impl abstract
	pop = function()
		if scene.current then scene.current.exit() end
		local previous = scene.stack[#scene.stack-1]
		if previous then previous.resume() end
		table.remove(scene.stack)
		scene.current = previous
	end,

	--- Update the current scene.
	-- Should be called in abstract.event.update.
	-- @tparam number dt the delta-time
	-- @impl abstract
	update = function(dt)
		if scene.current then
			scene.current.time.update(dt)
			scene.current.update(dt)
		end
	end,

	--- Draw the current scene.
	-- Should be called in abstract.event.draw.
	-- @impl abstract
	draw = function()
		if scene.current then scene.current.draw() end
	end
}

return scene
