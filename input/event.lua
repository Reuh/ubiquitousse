local signal = require((...):gsub("input%.event$", "signal"))
local max, min = math.max, math.min

--- This event registry is where every input object will listen for source events.
--
-- Available events:
-- * `"source.name"`: triggered when source.name (example input source name, replace with your own) is updated.
--   Must pass the arguments _new value_ (number), _filter_ (optional), _..._ (additional arguments for the filter, optional).
--   `filter` is an optional filter function that will be called by the listening inputs with arguments `filter(input object, new value, ...)`,
--   and should return the (eventually modified) new value. If it returns `nil`, the input will ignore the event (for example if the event concerns
--   a joystick that is not linked with the input).
-- * `"_active"`: triggered when any input is active, used for input detection in `onActiveNextSource`.
--   Must pass arguments _source name_ (string), _new value_, _filter_, _..._ (same arguments as other source updates, with source name added).
local event = signal.new()

local function update(source, new, filter, ...)
	event:emit(source, new, filter, ...)
	event:emit("_active", source, new, filter, ...)
end
local function impulse(source, new, filter, ...) -- input without release-like event; immediately release input
	event:emit(source, new, filter, ...)
	event:emit("_active", source, new, filter, ...)
	event:emit(source, 0, filter, ...)
end

local function joystickFilter(input, new, joystick)
	if input._joystick and joystick:getID() ~= input._joystick:getID() then
		return nil -- ignore if not from the selected joystick
	end
	return new
end
local function joystickAxisFilter(input, new, joystick)
	if input._joystick and joystick:getID() ~= input._joystick:getID() then
		return nil -- ignore if not from the selected joystick
	end
	local deadzone = input:_deadzone()
	if math.abs(new) < deadzone then
		return 0 -- apply deadzone on axis value
	else
		return new
	end
end

-- Binding LÖVE events --

signal.event:bind("keypressed", function(key, scancode, isrepeat)
	update(("key.%s"):format(key), 1)
	update(("scancode.%s"):format(scancode), 1)
end)
signal.event:bind("keyreleased", function(key, scancode)
	update(("key.%s"):format(key), 0)
	update(("scancode.%s"):format(scancode), 0)
end)

signal.event:bind("textinput", function(text)
	impulse(("text.%s"):format(text), 1)
end)

signal.event:bind("mousepressed", function(x, y, button, istouch, presses)
	update(("mouse.%s"):format(button), 1)
end)
signal.event:bind("mousereleased", function(x, y, button, istouch, presses)
	update(("mouse.%s"):format(button), 0)
end)

signal.event:bind("mousemoved", function(x, y, dx, dy, istouch)
	if     dx > 0 then impulse("mouse.dx.p", dx)
	elseif dx < 0 then impulse("mouse.dx.n", -dx) end
	if     dy > 0 then impulse("mouse.dy.p", dy)
	elseif dy < 0 then impulse("mouse.dy.n", -dy) end
	if     dx ~= 0 then impulse("mouse.dx", dx) end
	if     dy ~= 0 then impulse("mouse.dy", dy) end
	update("mouse.x", x)
	update("mouse.y", y)
end)

signal.event:bind("wheelmoved", function(x, y)
	if     x > 0 then impulse("wheel.x.p", x)
	elseif x < 0 then impulse("wheel.x.n", -x) end
	if     y > 0 then impulse("wheel.y.p", y)
	elseif y < 0 then impulse("wheel.y.n", -y) end
	if     x ~= 0 then impulse("wheel.x", x) end
	if     y ~= 0 then impulse("wheel.y", y) end
end)

signal.event:bind("gamepadpressed", function(joystick, button)
	update(("button.%s"):format(button), 1, joystickFilter, joystick)
end)
signal.event:bind("gamepadreleased", function(joystick, button)
	update(("button.%s"):format(button), 0, joystickFilter, joystick)
end)

signal.event:bind("gamepadaxis", function(joystick, axis, value)
	update(("axis.%s.p"):format(axis), max(value,0), joystickAxisFilter, joystick)
	update(("axis.%s.n"):format(axis), -min(value,0), joystickAxisFilter, joystick)
	update(("axis.%s"):format(axis), value, joystickAxisFilter, joystick)
end)

signal.event:bind("update", function(dt)
	event:emit("dt", dt) -- don't trigger _active event, as frankly that would be kinda stupid
end)

return event
