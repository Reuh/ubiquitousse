local timer = require((...):match("^(.-%.)backend").."timer")
local ctr = require("ctr")

timer.get = ctr.time

return timer