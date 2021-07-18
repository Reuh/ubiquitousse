-- ubiquitousse

--- Ubiquitousse Game Framework.
-- Main module, which will try to load every other Ubiquitousse module when required and provide a few convenience functions.
--
-- Ubiquitousse may or may not be used in its totality. You can delete the modules directories you don't need and Ubiquitousse
-- should adapt accordingly. You can also simply copy the modules directories you need and use them directly, without using this
-- file at all.
-- However, some modules may provide more feature when other modules are available.
-- These dependencies are written at the top of every main module file.
--
-- Ubiquitousse's goal is to run everywhere with the least porting effort possible, so while the current version mainly focus LÖVE, it
-- should be easily modifiable to work with something else. Ubiquitousse should only require:
-- * The backend needs to have access to some kind of main loop, or at least a function called very often (may or may not be the
--   same as the redraw screen callback).
-- * Some way of measuring time (preferably with millisecond-precision).
-- * Some kind of filesystem.
-- * Lua 5.1, 5.2, 5.3 or LuaJit.
-- * Other requirement for specific modules should be described in the module's documentation.
--
-- Functions that depends on LÖVE or anything that's not in the Lua standard libraries (and therefore the one you may want to port to
-- another framework) are indicated by a "-- @impl love" annotation.
--
-- Units used in the API documentation:
-- * All distances are expressed in pixels (px)
-- * All durations are expressed in seconds (ms)
-- These units are only used to make writing documentation easier; you can use other units if you want, as long as you're consistent.
--
-- Style:
-- * tabs for indentation, spaces for esthetic whitespace (notably in comments)
-- * no globals
-- * UPPERCASE for constants (or maybe not).
-- * CamelCase for class names.
-- * lowerCamelCase is expected for everything else.
--
-- For game writer:
-- Ubiquitousse works with Lua 5.1 to 5.3, including LuaJit, but doesn't provide any version checking or compatibility layer
-- between the different versions, so it's up to you to handle that in your game (or ignore the problem and sticks to your
-- main's backend Lua version).
--
-- Regarding the documentation: Ubiquitousse used LDoc/LuaDoc styled-comments, but since LDoc hates me and my code, the
-- generated result is complete garbage, so please read the documentation directly in the comments here until fix this.
-- Stuff you're interested in starts with triple - (e.g., "--- This functions saves the world").
--
-- @usage local ubiquitousse = require("ubiquitousse")

local p = ... -- require path
local ubiquitousse

ubiquitousse = {
	--- Ubiquitousse version.
	version = "0.1.0"
}

-- Check LÖVE version
local madeForLove = { 11, "x", "x" }

local actualLove = { love.getVersion() }
for i, v in ipairs(madeForLove) do
	if v ~= "x" and actualLove[i] ~= v then
		local txt = ("Ubiquitousse was made for LÖVE %s.%s.%s but %s.%s.%s is used!\nThings may not work as expected.")
			:format(madeForLove[1], madeForLove[2], madeForLove[3], actualLove[1], actualLove[2], actualLove[3])
		print(txt)
		love.window.showMessageBox("Compatibility warning", txt, "warning")
		break
	end
end

-- We're going to require modules requiring Ubiquitousse, so to avoid stack overflows we already register the ubiquitousse package
package.loaded[p] = ubiquitousse

-- Require external submodules
for _, m in ipairs{"signal", "asset", "ecs", "input", "scene", "timer", "util"} do
	local s, t = pcall(require, p.."."..m)
	if s then
		ubiquitousse[m] = t
	elseif not t:match("^module [^n]+ not found") then
		error(t)
	end
end

return ubiquitousse
