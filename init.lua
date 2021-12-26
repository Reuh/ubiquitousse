-- ubiquitousse

--- Ubiquitousse main module.
-- Set of various Lua libraries to make game development easier, mainly made to be used alongside the [LÖVE](https://love2d.org/) game framework.
-- Nothing that hasn't been done before, but these are tailored to what I need. They can be used independently too, and are relatively portable, even without LÖVE.
--
-- This is the main module, which will try to load every other Ubiquitousse module when required and may even provide a few convenience functions.
--
-- This also perform a quick LÖVE version check and show a warning in case of potential incompatibility.
--
-- **Regarding Ubiquitousse's organization**
--
-- Ubiquitousse may or may not be used in its totality. You can delete the modules directories you don't need and Ubiquitousse
-- should adapt accordingly. You can also simply copy the modules directories you need and use them directly, without using this
-- file at all.
-- However, some modules may provide more feature when other modules are available.
-- These dependencies are written at the top of every main module file.
--
-- Ubiquitousse's original goal was to run everywhere with the least porting effort possible, so while the current version now mainly focus LÖVE, it
-- should still be easily modifiable to work with something else. Ubiquitousse is mainly tested on LuaJIT and Lua 5.3 but should also support Lua 5.1 and 5.2.
-- In order to keep a good idea of how portable this all is, other dependencies, including LÖVE, are explicited at the top of every module file and in specific
-- functions definition using the `@require` tag (e.g., `-- @require love` for LÖVE).
--
-- Some modules are developped in [Candran](https://github.com/Reuh/candran) (.can files), but can easily be compiled into regular Lua code.
--
-- Units used in the API documentation, unless written otherwise:
--
-- * All distances are expressed in pixels (px)
-- * All durations are expressed in seconds (s)
--
-- These units are only used to make writing documentation easier; you can use other units if you want, as long as you're consistent.
--
-- Style:
--
-- * tabs for indentation, spaces for esthetic whitespace (notably in comments)
-- * no globals
-- * UPPERCASE for constants (or maybe not).
-- * CamelCase for class names.
-- * lowerCamelCase is expected for everything else.
--
-- Regarding the documentation: Ubiquitousse uses LDoc/LuaDoc styled-comments, but since LDoc hates me and my code, the
-- generated result is mostly garbage, so to generate the documentation you will need to use my [LDoc fork](https://github.com/Reuh/LDoc)
-- which I modified to force LDoc to like me.
--
-- @module ubiquitousse
-- @usage local ubiquitousse = require("ubiquitousse")

local p = ... -- require path
local ubiquitousse

ubiquitousse = {
	--- Ubiquitousse version string (currently `"0.1.0"`).
	version = "0.1.0",
	--- Asset manager module, if available.
	-- @see asset
	asset = nil,
	--- Entity Component System, if available.
	-- @see ecs
	ecs = nil,
	--- Input management, if available.
	-- TODO: not currently generated with LDoc.
	-- @see input
	input = nil,
	--- LDtk level import, if available.
	-- @see ldtk
	ldtk = nil,
	--- Scene management, if available.
	-- @see scene
	scene = nil,
	--- Signal management, if available.
	-- @see signal
	signal = nil,
	--- Timer utilities, if available.
	-- @see timer
	timer = nil,
	--- Various useful functions, if available.
	-- @see util
	util = nil
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
for _, m in ipairs{"signal", "asset", "ecs", "input", "scene", "timer", "util", "ldtk"} do
	local s, t = pcall(require, p.."."..m)
	if s then
		ubiquitousse[m] = t
	elseif not t:match("^module [^n]+ not found") then
		error(t)
	end
end

return ubiquitousse
