return { -- ./ecs/children.can:12
["name"] = "children", -- ./ecs/children.can:13
["filter"] = true, -- ./ecs/children.can:14
["onAdd"] = function(self, e) -- ./ecs/children.can:15
if not e["children"] then -- ./ecs/children.can:16
e["children"] = {} -- ./ecs/children.can:16
end -- ./ecs/children.can:16
if e["parent"] then -- ./ecs/children.can:17
local parentchildren -- ./ecs/children.can:18
parentchildren = e["parent"]["children"] -- ./ecs/children.can:18
table["insert"](parentchildren, e) -- ./ecs/children.can:19
end -- ./ecs/children.can:19
for _, o in ipairs(e["children"]) do -- ./ecs/children.can:21
o["parent"] = e -- ./ecs/children.can:22
self["world"]:add(o) -- ./ecs/children.can:23
end -- ./ecs/children.can:23
end, -- ./ecs/children.can:23
["onRemove"] = function(self, e) -- ./ecs/children.can:26
for i = # e["children"], 1, - 1 do -- ./ecs/children.can:27
self["world"]:remove(e["children"][i]) -- ./ecs/children.can:28
end -- ./ecs/children.can:28
if e["parent"] then -- ./ecs/children.can:30
local parentchildren -- ./ecs/children.can:31
parentchildren = e["parent"]["children"] -- ./ecs/children.can:31
for i = # parentchildren, 1, - 1 do -- ./ecs/children.can:32
if parentchildren[i] == e then -- ./ecs/children.can:33
table["remove"](parentchildren, i) -- ./ecs/children.can:34
break -- ./ecs/children.can:35
end -- ./ecs/children.can:35
end -- ./ecs/children.can:35
end -- ./ecs/children.can:35
end -- ./ecs/children.can:35
} -- ./ecs/children.can:35
