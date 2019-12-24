local input = require((...):match("^(.-%.)backend").."input")

-- Config --

-- Use ScanCodes (layout independant input) instead of KeyConstants (layout dependant) for keyboard input
local useScancodes = true
-- If using ScanCodes, sets this to true so the backend returns the layout-dependant KeyConstant
-- instead of the raw ScanCode when getting the display name. If set to false and using ScanCodes,
-- the user will see keys that don't match what's actually written on his keyboard, which is confusing.
local displayKeyConstant = true

-- Setup
love.mouse.setVisible(false)

-- Button detection
-- FIXME  love callbacks do something cleaner
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

-- Windows size
input.drawWidth, input.drawHeight = love.graphics.getWidth(), love.graphics.getHeight()
function love.resize(width, height)
	input.drawWidth = width
	input.drawHeight = height
end

-- Update
local oUpdate = input.update
input.update = function(dt)
	-- love.wheelmoved doesn't trigger when the wheel stop moving, so we need to clear up our stuff at each update
	buttonsInUse["mouse.wheel.up"] = nil
	buttonsInUse["mouse.wheel.down"] = nil
	buttonsInUse["mouse.wheel.right"] = nil
	buttonsInUse["mouse.wheel.left"] = nil
	-- Same for mouse axis
	axesInUse["mouse.move.x"] = nil
	axesInUse["mouse.move.y"] = nil

	oUpdate(dt)
end

input.basicButtonDetector = function(id)
	-- Keyboard
	if id:match("^keyboard%.") then
		local key = id:match("^keyboard%.(.+)$")
		return function()
			return useScancodes and love.keyboard.isScancodeDown(key) or love.keyboard.isDown(key)
		end
	-- Mouse wheel
	elseif id:match("^mouse%.wheel%.") then
		local key = id:match("^mouse%.wheel%.(.+)$")
		return function()
			return buttonsInUse["mouse.wheel."..key]
		end
	-- Mouse
	elseif id:match("^mouse%.") then
		local key = id:match("^mouse%.(.+)$")
		return function()
			return love.mouse.isDown(key)
		end
	-- Gamepad button
	elseif id:match("^gamepad%.button%.") then
		local gid, key = id:match("^gamepad%.button%.(.+)%.(.+)$")
		gid = tonumber(gid)
		return function()
			local gamepad
			for _,j in ipairs(love.joystick.getJoysticks()) do
				if j:getID() == gid then gamepad = j end
			end
			return gamepad and gamepad:isGamepadDown(key)
		end
	-- Gamepad axis
	elseif id:match("^gamepad%.axis%.") then
		local gid, axis, threshold = id:match("^gamepad%.axis%.(.+)%.(.+)%%(.+)$")
		if not gid then gid, axis = id:match("^gamepad%.axis%.(.+)%.(.+)$") end -- no threshold (=0)
		gid = tonumber(gid)
		threshold = tonumber(threshold) or 0.1
		return function()
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
		end
	else
		error("Unknown button identifier: "..id)
	end
end

input.basicAxisDetector = function(id)
	-- Mouse movement
	if id:match("^mouse%.move%.") then
		local axis, threshold = id:match("^mouse%.move%.(.+)%%(.+)$")
		if not axis then axis = id:match("^mouse%.move%.(.+)$") end -- no threshold (=0)
		threshold = tonumber(threshold) or 0
		return function()
			local val, raw, max = axesInUse["mouse.move."..axis] or 0, 0, 1
			if axis == "x" then
				raw, max = val * love.graphics.getWidth(), love.graphics.getWidth()
			elseif axis == "y" then
				raw, max = val * love.graphics.getHeight(), love.graphics.getHeight()
			end
			return math.abs(val) > math.abs(threshold) and val or 0, raw, max
		end
	-- Mouse position
	elseif id:match("^mouse%.position%.") then
		local axis, threshold = id:match("^mouse%.position%.(.+)%%(.+)$")
		if not axis then axis = id:match("^mouse%.position%.(.+)$") end -- no threshold (=0)
		threshold = tonumber(threshold) or 0
		return function()
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
		end
	-- Gamepad axis
	elseif id:match("^gamepad%.axis%.") then
		local gid, axis, threshold = id:match("^gamepad%.axis%.(.+)%.(.+)%%(.+)$")
		if not gid then gid, axis = id:match("^gamepad%.axis%.(.+)%.(.+)$") end -- no threshold (=0)
		gid = tonumber(gid)
		threshold = tonumber(threshold) or 0.1
		return function()
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
		end
	else
		error("Unknown axis identifier: "..id)
	end
end

input.buttonsInUse = function(threshold)
	local r = {}
	threshold = threshold or 0.5
	for b in pairs(buttonsInUse) do
		table.insert(r, b)
	end
	for b,v in pairs(axesInUse) do
		if math.abs(v) > threshold then
			table.insert(r, b.."%"..(v < 0 and -threshold or threshold))
		end
	end
	return r
end

input.axesInUse = function(threshold)
	local r = {}
	threshold = threshold or 0.5
	for b,v in pairs(axesInUse) do
		if math.abs(v) > threshold then
			table.insert(r, b.."%"..threshold)
		end
	end
	return r
end

input.buttonName = function(...)
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
			threshold = tonumber(threshold) or 0.1
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
			table.insert(ret, id)
		end
	end
	return unpack(ret)
end

input.axisName = function(...)
	local ret = {}
	for _,id in ipairs({...}) do
		-- Binary axis
		if id:match(".+%,.+") then
			local b1, b2 = input.buttonName(id:match("^(.+)%,(.+)$"))
			table.insert(ret, b1.." / "..b2)
		-- Mouse movement
		elseif id:match("^mouse%.move%.") then
			local axis, threshold = id:match("^mouse%.move%.(.+)%%(.+)$")
			if not axis then axis = id:match("^mouse%.move%.(.+)$") end -- no threshold (=0)
			threshold = tonumber(threshold) or 0
			table.insert(ret, ("Mouse %s movement (threshold %s%%)"):format(axis, math.abs(threshold*100)))
		-- Mouse position
		elseif id:match("^mouse%.position%.") then
			local axis, threshold = id:match("^mouse%.position%.(.+)%%(.+)$")
			if not axis then axis = id:match("^mouse%.position%.(.+)$") end -- no threshold (=0)
			threshold = tonumber(threshold) or 0
			table.insert(ret, ("Mouse %s position (threshold %s%%)"):format(axis, math.abs(threshold*100)))
		-- Gamepad axis
		elseif id:match("^gamepad%.axis%.") then
			local gid, axis, threshold = id:match("^gamepad%.axis%.(.+)%.(.+)%%(.+)$")
			if not gid then gid, axis = id:match("^gamepad%.axis%.(.+)%.(.+)$") end -- no threshold (=0)
			threshold = tonumber(threshold) or 0.1
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
			table.insert(ret, id)
		end
	end
	return unpack(ret)
end

-- Default inputs.
input.default.pointer:bind(
	{ "absolute", { "keyboard.left", "keyboard.right" }, { "keyboard.up", "keyboard.down" } },
	{ "absolute", { "keyboard.a", "keyboard.d" }, { "keyboard.w", "keyboard.s" } },
	{ "absolute", "gamepad.axis.1.leftx", "gamepad.axis.1.lefty" },
	{ "absolute", { "gamepad.button.1.dpleft", "gamepad.button.1.dpright" }, { "gamepad.button.1.dpup", "gamepad.button.1.dpdown" } }
)
input.default.confirm:bind(
	"keyboard.return", "keyboard.space", "keyboard.lshift", "keyboard.e",
	"gamepad.button.1.a"
)
input.default.cancel:bind(
	"keyboard.escape", "keyboard.backspace",
	"gamepad.button.1.b"
)

return input
