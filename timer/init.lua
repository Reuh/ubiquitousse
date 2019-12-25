local time

local p = ...
if love then
	time = require(p..".backend.love")
elseif package.loaded["ctr"] then
	time = require(p..".backend.ctrulua")
elseif package.loaded["libretro"] then
	error("NYI")
else
	error("no backend for ubiquitousse.timer")
end

return time
