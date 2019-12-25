local timer = require((...):match("^(.-%.)backend").."timer")

timer.get = function()
	return love.timer.getTime() * 1000
end

return timer