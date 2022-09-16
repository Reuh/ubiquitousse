local whiteTexture -- ./gltf/draw.can:4
whiteTexture = love["graphics"]["newCanvas"](2, 2) -- ./gltf/draw.can:4
whiteTexture:renderTo(function() -- ./gltf/draw.can:5
love["graphics"]["setColor"](1, 1, 1) -- ./gltf/draw.can:6
love["graphics"]["rectangle"]("fill", 0, 0, 2, 2) -- ./gltf/draw.can:7
end) -- ./gltf/draw.can:7
local maybeSend -- ./gltf/draw.can:11
maybeSend = function(s, name, val) -- ./gltf/draw.can:11
if s:hasUniform(name) then -- ./gltf/draw.can:12
s:send(name, val) -- ./gltf/draw.can:13
end -- ./gltf/draw.can:13
end -- ./gltf/draw.can:13
local maybeSendTexture -- ./gltf/draw.can:16
maybeSendTexture = function(s, name, tex) -- ./gltf/draw.can:16
if s:hasUniform(name) then -- ./gltf/draw.can:17
if tex then -- ./gltf/draw.can:18
s:send(name, tex["index"]["image"]) -- ./gltf/draw.can:19
else -- ./gltf/draw.can:19
s:send(name, whiteTexture) -- ./gltf/draw.can:21
end -- ./gltf/draw.can:21
end -- ./gltf/draw.can:21
end -- ./gltf/draw.can:21
local applyMaterial -- ./gltf/draw.can:27
applyMaterial = function(s, mat) -- ./gltf/draw.can:27
maybeSend(s, "baseColorFactor", mat["pbrMetallicRoughness"]["baseColorFactor"]) -- ./gltf/draw.can:28
maybeSendTexture(s, "baseColorTexture", mat["pbrMetallicRoughness"]["baseColorTexture"]) -- ./gltf/draw.can:29
maybeSend(s, "metallicFactor", mat["pbrMetallicRoughness"]["metallicFactor"]) -- ./gltf/draw.can:30
maybeSend(s, "roughnessFactor", mat["pbrMetallicRoughness"]["roughnessFactor"]) -- ./gltf/draw.can:31
maybeSendTexture(s, "metallicRoughnessTexture", mat["pbrMetallicRoughness"]["metallicRoughnessTexture"]) -- ./gltf/draw.can:32
maybeSendTexture(s, "normalTexture", mat["normalTexture"]) -- ./gltf/draw.can:33
maybeSendTexture(s, "occlusionTexture", mat["occlusionTexture"]) -- ./gltf/draw.can:34
if mat["occlusionTexture"] then -- ./gltf/draw.can:35
maybeSend(s, "occlusionTextureStrength", mat["occlusionTexture"]["strength"]) -- ./gltf/draw.can:36
else -- ./gltf/draw.can:36
maybeSend(s, "occlusionTextureStrength", 1) -- ./gltf/draw.can:38
end -- ./gltf/draw.can:38
maybeSendTexture(s, "emissiveTexture", mat["emissiveTexture"]) -- ./gltf/draw.can:40
if mat["emissiveTexture"] then -- ./gltf/draw.can:41
maybeSend(s, "emissiveTextureScale", mat["emissiveTexture"]["scale"]) -- ./gltf/draw.can:42
else -- ./gltf/draw.can:42
maybeSend(s, "emissiveTextureScale", 1) -- ./gltf/draw.can:44
end -- ./gltf/draw.can:44
maybeSend(s, "emissiveFactor", mat["emissiveFactor"]) -- ./gltf/draw.can:46
if mat["alphaMode"] == "BLEND" then -- ./gltf/draw.can:47
love["graphics"]["setBlendMode"]("alpha") -- ./gltf/draw.can:48
maybeSend(s, "alphaCutoff", 0) -- ./gltf/draw.can:49
else -- ./gltf/draw.can:49
love["graphics"]["setBlendMode"]("replace") -- ./gltf/draw.can:51
maybeSend(s, "alphaCutoff", mat["alphaMode"] == "BLEND" and mat["alphaCutoff"] or 0) -- ./gltf/draw.can:52
end -- ./gltf/draw.can:52
if mat["doubleSided"] then -- ./gltf/draw.can:54
love["graphics"]["setMeshCullMode"]("none") -- ./gltf/draw.can:55
else -- ./gltf/draw.can:55
love["graphics"]["setMeshCullMode"]("back") -- ./gltf/draw.can:57
end -- ./gltf/draw.can:57
end -- ./gltf/draw.can:57
local drawNode -- ./gltf/draw.can:62
drawNode = function(node, s) -- ./gltf/draw.can:62
if node["mesh"] then -- ./gltf/draw.can:63
s:send("modelMatrix", "column", node["matrix"]) -- ./gltf/draw.can:64
for _, primitive in ipairs(node["mesh"]["primitives"]) do -- ./gltf/draw.can:65
applyMaterial(s, primitive["material"]) -- ./gltf/draw.can:66
love["graphics"]["draw"](primitive["mesh"]) -- ./gltf/draw.can:67
end -- ./gltf/draw.can:67
end -- ./gltf/draw.can:67
for _, child in ipairs(node["children"]) do -- ./gltf/draw.can:70
drawNode(child, s) -- ./gltf/draw.can:71
end -- ./gltf/draw.can:71
end -- ./gltf/draw.can:71
local drawMainScene -- ./gltf/draw.can:77
drawMainScene = function(gltf, s) -- ./gltf/draw.can:77
love["graphics"]["push"]("all") -- ./gltf/draw.can:78
love["graphics"]["setDepthMode"]("lequal", true) -- ./gltf/draw.can:79
if s then -- ./gltf/draw.can:80
love["graphics"]["setShader"](s) -- ./gltf/draw.can:81
else -- ./gltf/draw.can:81
s = love["graphics"]["getShader"]() -- ./gltf/draw.can:83
end -- ./gltf/draw.can:83
for _, node in ipairs(gltf["scene"]["nodes"]) do -- ./gltf/draw.can:85
drawNode(node, s) -- ./gltf/draw.can:86
end -- ./gltf/draw.can:86
love["graphics"]["pop"]("all") -- ./gltf/draw.can:88
end -- ./gltf/draw.can:88
return drawMainScene -- ./gltf/draw.can:91
