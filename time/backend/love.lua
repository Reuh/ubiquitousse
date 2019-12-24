local time = require((...):match("^(.-%.)backend").."time")

time.get = function()
	return love.timer.getTime() * 1000
end

return time