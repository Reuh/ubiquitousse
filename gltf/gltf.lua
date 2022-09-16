local loader -- ./gltf/gltf.can:3
loader = require((...):gsub("gltf$", "loader")) -- ./gltf/gltf.can:3
local draw -- ./gltf/gltf.can:4
draw = require((...):gsub("gltf$", "draw")) -- ./gltf/gltf.can:4
local gltf_mt -- ./gltf/gltf.can:7
gltf_mt = { -- ./gltf/gltf.can:7
["gltf"] = nil, -- ./gltf/gltf.can:9
["draw"] = function(self, shader) -- ./gltf/gltf.can:12
draw(self["gltf"], shader) -- ./gltf/gltf.can:13
end -- ./gltf/gltf.can:13
} -- ./gltf/gltf.can:13
gltf_mt["__index"] = gltf_mt -- ./gltf/gltf.can:16
return function(path) -- ./gltf/gltf.can:19
return setmetatable({ ["gltf"] = loader(path) }, gltf_mt) -- ./gltf/gltf.can:22
end -- ./gltf/gltf.can:22
