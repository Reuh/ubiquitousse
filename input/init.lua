local input

local p = ...
if love then
	input = require(p..".backend.love")
elseif package.loaded["ctr"] then
	input = require(p..".backend.ctrulua")
elseif package.loaded["libretro"] then
	error("NYI")
else
	error("no backend for ubiquitousse.input")
end

return input
