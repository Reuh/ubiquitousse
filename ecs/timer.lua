local timer -- ./ecs/timer.can:4
timer = require((...):match("^(.-)ecs%.timer") .. "scene") -- ./ecs/timer.can:4
return { -- ./ecs/timer.can:6
["name"] = "timer", -- ./ecs/timer.can:7
["filter"] = "timer", -- ./ecs/timer.can:8
["default"] = {}, -- ./ecs/timer.can:9
["process"] = function(self, t, dt) -- ./ecs/timer.can:12
t:update(dt) -- ./ecs/timer.can:13
if t:dead() then -- ./ecs/timer.can:14
self["world"]:remove(t["entity"]) -- ./ecs/timer.can:15
end -- ./ecs/timer.can:15
end, -- ./ecs/timer.can:15
["run"] = function(self, func) -- ./ecs/timer.can:20
local t = timer["run"](func) -- ./ecs/timer.can:21
self["world"]:add({ ["timer"] = t }) -- ./ecs/timer.can:23
return t -- ./ecs/timer.can:25
end, -- ./ecs/timer.can:25
["tween"] = function(self, duration, tbl, to, method) -- ./ecs/timer.can:28
local t = timer["tween"](duration, tbl, to, method) -- ./ecs/timer.can:29
self["world"]:add({ ["timer"] = t }) -- ./ecs/timer.can:31
return t -- ./ecs/timer.can:33
end -- ./ecs/timer.can:33
} -- ./ecs/timer.can:33
