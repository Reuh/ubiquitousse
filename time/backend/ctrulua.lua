local time = require((...):match("^(.-%.)backend").."time")
local ctr = require("ctr")

time.get = ctr.time

return time