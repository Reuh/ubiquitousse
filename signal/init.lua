local signal

local p = ...
if love then
	signal = require(p..".backend.love")
elseif package.loaded["ctr"] then
	error("NYI")
elseif package.loaded["libretro"] then
	error("NYI")
else
	error("no backend for ubiquitousse.signal")
end

return signal