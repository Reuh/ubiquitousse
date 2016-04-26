--- Löve backend 0.0.1 for Abstract.
-- Provides all the Abstract API on a Löve environment.
-- Made for Löve 0.10.1 and abstract 0.0.1.
-- See `abstract` for Abstract API.

-- Config
local useScancodes = true -- Use ScanCodes (layout independant input) instead of KeyConstants (layout dependant) for keyboard input
local displayKeyConstant = true -- If using ScanCodes, sets this to true so the backend returns the layout-dependant KeyConstant
                                -- instead of the raw ScanCode when getting the display name. If set to false and using ScanCodes,
                                -- the user will see keys that don't match what's actually written on his keyboard, which is confusing.

-- General
local version = "0.0.1"

-- Require stuff
local abstract = require((...):match("^(.-abstract)%."))

-- Version compatibility warning
do
	local function checkCompat(stuffName, expectedVersion, actualVersion)
		if actualVersion ~= expectedVersion then
			local txt = ("Abstract Löve backend version "..version.." was made for %s %s but %s is used!\nThings may not work as expected.")
			            :format(stuffName, expectedVersion, actualVersion)
			print(txt)
			love.window.showMessageBox("Warning", txt, "warning")
		end
	end
	checkCompat("Löve", "0.10.1", ("%s.%s.%s"):format(love.getVersion()))
	checkCompat("abstract", "0.0.1", abstract.version)
end

-- Redefine all functions in tbl which also are in toAdd, so when used they call the old function (in tbl) and then the new (in toAdd).
local function add(tbl, toAdd)
	for k,v in pairs(toAdd) do
		local old = tbl[k]
		tbl[k] = function(...)
			old(...)
			return v(...)
		end
	end
end

-- abstract
abstract.backend = "love"

-- abstract.event
do
local updateDefault = abstract.event.update
abstract.event.update = function() end
function love.update(dt)
	-- Value update
	abstract.draw.fps = love.timer.getFPS()

	-- Stuff defined in abstract.lua
	updateDefault(dt)

	-- Callback
	abstract.event.update(dt)
end

local drawDefault = abstract.event.draw
abstract.event.draw = function() end
function love.draw()
	love.graphics.push()

	-- Resize type
	local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
	local gameW, gameH = abstract.draw.params.width, abstract.draw.params.height
	if abstract.draw.params.resizeType == "auto" then
		love.graphics.scale(winW/gameW, winH/gameH)
	elseif abstract.draw.params.resizeType == "center" then
		love.graphics.translate(math.floor(winW/2-gameW/2), math.floor(winH/2-gameH/2))
	end

	-- Stuff defined in abstract.lua
	drawDefault()

	-- Callback
	abstract.event.draw()

	love.graphics.pop()
end
end

-- abstract.draw
local defaultFont = love.graphics.getFont()
add(abstract.draw, {
	init = function(params)
		local p = abstract.draw.params
		love.window.setTitle(p.title)
		love.window.setMode(p.width, p.height, {
			resizable = p.resizable
		})
	end,
	color = function(r, g, b, a)
		love.graphics.setColor(r, g, b, a)
	end,
	text = function(x, y, text)
		love.graphics.setFont(defaultFont)
		love.graphics.print(text, x, y)
	end,
	line = function(x1, y1, x2, y2)
		love.graphics.line(x1, y1, x2, y2)
	end,
	rectangle = function(x, y, width, height)
		love.graphics.rectangle("fill", x, y, width, height)
	end,
	scissor = function(x, y, width, height)
		love.graphics.setScissor(x, y, width, height)
	end,
	-- TODO: doc
	image = function(filename)
		local img = love.graphics.newImage(filename)
		return {
			width = img:getWidth(),
			height = img:getHeight(),
			draw = function(self, x, y, r, sx, sy, ox, oy)
				love.graphics.draw(img, x, y, r, sx, sy, ox, oy)
			end
		}
	end,
	font = function(filename, size)
		local fnt = love.graphics.newFont(filename, size)
		return {
			width = function(self, text)
				return fnt:getWidth(text)
			end,
			draw = function(self, text, x, y, r, sx, sy, ox, oy)
				love.graphics.setFont(fnt)
				love.graphics.print(text, x, y, r, sx, sy, ox, oy)
			end
		}
	end,
})
function love.resize(width, height)
	if abstract.draw.params.resizeType == "none" then
		abstract.draw.width = width
		abstract.draw.height = height
	end
end

-- abstract.audio
add(abstract.audio, {
	-- TODO: doc
	load = function(filepath)
		local audio = love.audio.newSource(filepath)
		return {
			play = function(self)
				audio:play()
			end
		}
	end
})

-- abstract.time
add(abstract.time, {
	get = function()
		return love.timer.getTime()
	end
})

-- abstract.input
do
local buttonsInUse = {}
local axesInUse = {}
function love.keypressed(key, scancode, isrepeat)
	if useScancodes then key = scancode end
	buttonsInUse["keyboard."..key] = true
end
function love.keyreleased(key, scancode)
	if useScancodes then key = scancode end
	buttonsInUse["keyboard."..key] = nil
end
function love.mousepressed(x, y, button, istouch)
	buttonsInUse["mouse."..button] = true
end
function love.mousereleased(x, y, button, istouch)
	buttonsInUse["mouse."..button] = nil
end
function love.wheelmoved(x, y)
	if y > 0 then
		buttonsInUse["mouse.wheel.up"] = true
	elseif y < 0 then
		buttonsInUse["mouse.wheel.down"] = true
	end
	if x > 0 then
		buttonsInUse["mouse.wheel.right"] = true
	elseif x < 0 then
		buttonsInUse["mouse.wheel.left"] = true
	end
end
function love.mousemoved(x, y, dx, dy)
	if dx ~= 0 then axesInUse["mouse.move.x"] = dx/love.graphics.getWidth() end
	if dy ~= 0 then axesInUse["mouse.move.y"] = dy/love.graphics.getHeight() end
end
-- love.wheelmoved doesn't trigger when the wheel stop moving, so we need to clear up our stuff after love.update (so in love.draw)
add(love, {
	draw = function()
		buttonsInUse["mouse.wheel.up"] = nil
		buttonsInUse["mouse.wheel.down"] = nil
		buttonsInUse["mouse.wheel.right"] = nil
		buttonsInUse["mouse.wheel.left"] = nil
		-- Same for mouse axis
		axesInUse["mouse.move.x"] = nil
		axesInUse["mouse.move.y"] = nil
	end
})
function love.gamepadpressed(joystick, button)
	buttonsInUse["gamepad.button."..joystick:getID().."."..button] = true
end
function love.gamepadreleased(joystick, button)
	buttonsInUse["gamepad.button."..joystick:getID().."."..button] = nil
end
function love.gamepadaxis(joystick, axis, value)
	if value ~= 0 then
		axesInUse["gamepad.axis."..joystick:getID().."."..axis] = value
	else
		axesInUse["gamepad.axis."..joystick:getID().."."..axis] = nil
	end
end

love.mouse.setVisible(false)

add(abstract.input, {
	buttonDetector = function(...)
		local ret = {}
		for _,id in ipairs({...}) do
			-- Keyboard
			if id:match("^keyboard%.") then
				local key = id:match("^keyboard%.(.+)$")
				table.insert(ret, function()
					return useScancodes and love.keyboard.isScancodeDown(key) or love.keyboard.isDown(key)
				end)
			-- Mouse wheel
			elseif id:match("^mouse%.wheel%.") then
				local key = id:match("^mouse%.wheel%.(.+)$")
				table.insert(ret, function()
					return buttonsInUse["mouse.wheel."..key]
				end)
			-- Mouse
			elseif id:match("^mouse%.") then
				local key = id:match("^mouse%.(.+)$")
				table.insert(ret, function()
					return love.mouse.isDown(key)
				end)
			-- Gamepad button
			elseif id:match("^gamepad%.button%.") then
				local gid, key = id:match("^gamepad%.button%.(.+)%.(.+)$")
				gid = tonumber(gid)
				table.insert(ret, function()
					local gamepad
					for _,j in ipairs(love.joystick.getJoysticks()) do
						if j:getID() == gid then gamepad = j end
					end
					return gamepad and gamepad:isGamepadDown(key)
				end)
			-- Gamepad axis
			elseif id:match("^gamepad%.axis%.") then
				local gid, axis, threshold = id:match("^gamepad%.axis%.(.+)%.(.+)%%(.+)$")
				if not gid then gid, axis = id:match("^gamepad%.axis%.(.+)%.(.+)$") end -- no threshold (=0)
				gid = tonumber(gid)
				threshold = tonumber(threshold) or 0
				table.insert(ret, function()
					local gamepad
					for _,j in ipairs(love.joystick.getJoysticks()) do
						if j:getID() == gid then gamepad = j end
					end
					if not gamepad then
						return false
					else
						local val = gamepad:getGamepadAxis(axis)
						return (math.abs(val) > math.abs(threshold)) and ((val < 0) == (threshold < 0))
					end
				end)
			else
				error("Unknown button identifier: "..id)
			end
		end
		return unpack(ret)
	end,

	axisDetector = function(...)
		local ret = {}
		for _,id in ipairs({...}) do
			-- Binary axis
			if id:match(".+%,.+") then
				local d1, d2 = abstract.input.buttonDetector(id:match("^(.+)%,(.+)$"))
				table.insert(ret, function()
					local b1, b2 = d1(), d2()
					if b1 and b2 then return 0
					elseif b1 then return -1
					elseif b2 then return 1
					else return 0 end
				end)
			-- Mouse movement
			elseif id:match("^mouse%.move%.") then
				local axis, threshold = id:match("^mouse%.move%.(.+)%%(.+)$")
				if not axis then axis = id:match("^mouse%.move%.(.+)$") end -- no threshold (=0)
				threshold = tonumber(threshold) or 0
				table.insert(ret, function()
					local val, raw, max = axesInUse["mouse.move."..axis] or 0, 0, 1
					if axis == "x" then
						raw, max = val * love.graphics.getWidth(), love.graphics.getWidth()
					elseif axis == "y" then
						raw, max = val * love.graphics.getHeight(), love.graphics.getHeight()
					end
					return math.abs(val) > math.abs(threshold) and val or 0, raw, max
				end)
			-- Mouse position
			elseif id:match("^mouse%.position%.") then
				local axis, threshold = id:match("^mouse%.position%.(.+)%%(.+)$")
				if not axis then axis = id:match("^mouse%.position%.(.+)$") end -- no threshold (=0)
				threshold = tonumber(threshold) or 0
				table.insert(ret, function()
					local val, raw, max = 0, 0, 1
					if axis == "x" then
						max = love.graphics.getWidth() / 2 -- /2 because x=0,y=0 is the center of the screen (an axis value is in [-1,1])
						raw = love.mouse.getX() - max
					elseif axis == "y" then
						max = love.graphics.getHeight() / 2
						raw = love.mouse.getY() - max
					end
					val = raw / max
					return math.abs(val) > math.abs(threshold) and val or 0, raw, max
				end)
			-- Gamepad axis
			elseif id:match("^gamepad%.axis%.") then
				local gid, axis, threshold = id:match("^gamepad%.axis%.(.+)%.(.+)%%(.+)$")
				if not gid then gid, axis = id:match("^gamepad%.axis%.(.+)%.(.+)$") end -- no threshold (=0)
				gid = tonumber(gid)
				threshold = tonumber(threshold) or 0
				table.insert(ret, function()
					local gamepad
					for _,j in ipairs(love.joystick.getJoysticks()) do
						if j:getID() == gid then gamepad = j end
					end
					if not gamepad then
						return 0
					else
						local val = gamepad:getGamepadAxis(axis)
						return math.abs(val) > math.abs(threshold) and val or 0
					end
				end)
			else
				error("Unknown axis identifier: "..id)
			end
		end
		return unpack(ret)
	end,

	buttonsInUse = function(threshold)
		local r = {}
		local threshold = threshold or 0.5
		for b in pairs(buttonsInUse) do
			table.insert(r, b)
		end
		for b,v in pairs(axesInUse) do
			if math.abs(v) > threshold then
				table.insert(r, b.."%"..(v < 0 and -threshold or threshold))
			end
		end
		return r
	end,

	axesInUse = function(threshold)
		local r = {}
		local threshold = threshold or 0.5
		for b,v in pairs(axesInUse) do
			if math.abs(v) > threshold then
				table.insert(r, b.."%"..threshold)
			end
		end
		return r
	end,

	buttonName = function(...)
		local ret = {}
		for _,id in ipairs({...}) do
			-- Keyboard
			if id:match("^keyboard%.") then
				local key = id:match("^keyboard%.(.+)$")
				if useScancodes and displayKeyConstant then key = love.keyboard.getKeyFromScancode(key) end
				table.insert(ret, key:sub(1,1):upper()..key:sub(2).." key")
			-- Mouse wheel
			elseif id:match("^mouse%.wheel%.") then
				local key = id:match("^mouse%.wheel%.(.+)$")
				table.insert(ret, "Mouse wheel "..key)
			-- Mouse
			elseif id:match("^mouse%.") then
				local key = id:match("^mouse%.(.+)$")
				table.insert(ret, "Mouse "..key)
			-- Gamepad button
			elseif id:match("^gamepad%.button%.") then
				local gid, key = id:match("^gamepad%.button%.(.+)%.(.+)$")
				table.insert(ret, "Gamepad "..gid.." button "..key)
			-- Gamepad axis
			elseif id:match("^gamepad%.axis%.") then
				local gid, axis, threshold = id:match("^gamepad%.axis%.(.+)%.(.+)%%(.+)$")
				if not gid then gid, axis = id:match("^gamepad%.axis%.(.+)%.(.+)$") end -- no threshold (=0)
				threshold = tonumber(threshold) or 0
				if axis == "rightx" then
					table.insert(ret, ("Gamepad %s right stick %s (deadzone %s%%)"):format(gid, threshold >= 0 and "right" or "left", math.abs(threshold*100)))
				elseif axis == "righty" then
					table.insert(ret, ("Gamepad %s right stick %s (deadzone %s%%)"):format(gid, threshold >= 0 and "down" or "up", math.abs(threshold*100)))
				elseif axis == "leftx" then
					table.insert(ret, ("Gamepad %s left stick %s (deadzone %s%%)"):format(gid, threshold >= 0 and "right" or "left", math.abs(threshold*100)))
				elseif axis == "lefty" then
					table.insert(ret, ("Gamepad %s left stick %s (deadzone %s%%)"):format(gid, threshold >= 0 and "down" or "up", math.abs(threshold*100)))
				else
					table.insert(ret, ("Gamepad %s axis %s (deadzone %s%%)"):format(gid, axis, math.abs(threshold*100)))
				end
			else
				table.insert(r, id)
			end
		end
		return unpack(ret)
	end,

	axisName = function(...)
		local ret = {}
		for _,id in ipairs({...}) do
			-- Binary axis
			if id:match(".+%,.+") then
				local b1, b2 = abstract.input.buttonName(id:match("^(.+)%,(.+)$"))
				table.insert(ret, b1.." / "..b2)
			-- Mouse move
			elseif id:match("^mouse%.move%.") then
				local axis, threshold = id:match("^mouse%.move%.(.+)%%(.+)$")
				if not axis then axis = id:match("^mouse%.move%.(.+)$") end -- no threshold (=0)
				threshold = tonumber(threshold) or 0
				table.insert(ret, ("Mouse %s movement (threshold %s%%)"):format(axis, math.abs(threshold*100)))
			-- Mouse move
			elseif id:match("^mouse%.position%.") then
				local axis, threshold = id:match("^mouse%.position%.(.+)%%(.+)$")
				if not axis then axis = id:match("^mouse%.position%.(.+)$") end -- no threshold (=0)
				threshold = tonumber(threshold) or 0
				table.insert(ret, ("Mouse %s position (threshold %s%%)"):format(axis, math.abs(threshold*100)))
			-- Gamepad axis
			elseif id:match("^gamepad%.axis%.") then
				local gid, axis, threshold = id:match("^gamepad%.axis%.(.+)%.(.+)%%(.+)$")
				if not gid then gid, axis = id:match("^gamepad%.axis%.(.+)%.(.+)$") end -- no threshold (=0)
				threshold = tonumber(threshold) or 0
				if axis == "rightx" then
					table.insert(ret, ("Gamepad %s right stick %s (deadzone %s%%)"):format(gid, threshold >= 0 and "right" or "left", math.abs(threshold*100)))
				elseif axis == "righty" then
					table.insert(ret, ("Gamepad %s right stick %s (deadzone %s%%)"):format(gid, threshold >= 0 and "down" or "up", math.abs(threshold*100)))
				elseif axis == "leftx" then
					table.insert(ret, ("Gamepad %s left stick %s (deadzone %s%%)"):format(gid, threshold >= 0 and "right" or "left", math.abs(threshold*100)))
				elseif axis == "lefty" then
					table.insert(ret, ("Gamepad %s left stick %s (deadzone %s%%)"):format(gid, threshold >= 0 and "down" or "up", math.abs(threshold*100)))
				else
					table.insert(ret, ("Gamepad %s axis %s (deadzone %s%%)"):format(gid, axis, math.abs(threshold*100)))
				end
			else
				table.insert(r, id)
			end
		end
		return unpack(ret)
	end
})

-- Defaults
abstract.input.default.pointer:bind(
	{ "absolute", "keyboard.left,keyboard.right", "keyboard.up,keyboard.down" },
	{ "absolute", "gamepad.axis.1.leftx", "gamepad.axis.1.lefty" }
)
abstract.input.default.up:bind(
	"keyboard.up", "keyboard.w",
	"gamepad.button.1.dpup", "gamepad.axis.1.lefty%-0.5"
)
abstract.input.default.down:bind(
	"keyboard.down", "keyboard.s",
	"gamepad.button.1.dpdown", "gamepad.axis.1.lefty%0.5"
)
abstract.input.default.right:bind(
	"keyboard.right", "keyboard.d",
	"gamepad.button.1.dpright", "gamepad.axis.1.leftx%0.5"
)
abstract.input.default.left:bind(
	"keyboard.left", "keyboard.a",
	"gamepad.button.1.dpleft", "gamepad.axis.1.leftx%-0.5"
)
abstract.input.default.confirm:bind(
	"keyboard.enter", "keyboard.space", "keyboard.lshift", "keyboard.e",
	"gamepad.button.1.a"
)
abstract.input.default.cancel:bind(
	"keyboard.escape", "keyboard.backspace",
	"gamepad.button.1.b"
)
end
