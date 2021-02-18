local signal = require((...):match("^(.-%.)backend").."signal")

function signal.registerEvents()
	local callbacks = { -- everything except run, errorhandler, threaderror
		"displayrotated", "draw", "load", "lowmemory", "quit", "update",
		"directorydropped", "filedropped", "focus", "mousefocus", "resize", "visible",
		"keypressed", "keyreleased", "textedited", "textinput",
		"mousemoved", "mousepressed", "mousereleased", "wheelmoved",
		"gamepadaxis", "gamepadpressed", "gamepadreleased",
		"joystickadded", "joystickaxis", "joystickhat", "joystickpressed", "joystickreleased", "joystickremoved",
		"touchmoved", "touchpressed", "touchreleased"
	}
	local event = signal.event
	for _, callback in ipairs(callbacks) do
		if callback == "update" then
			if love[callback] then
				local old = love[callback]
				love[callback] = function(dt)
					old(dt)
					event:emit(callback, dt)
				end
			else
				love[callback] = function(dt)
					event:emit(callback, dt)
				end
			end
		else
			if love[callback] then
				local old = love[callback]
				love[callback] = function(...)
					old(...)
					event:emit(callback, ...)
				end
			else
				love[callback] = function(...)
					event:emit(callback, ...)
				end
			end
		end
	end
end

return signal
