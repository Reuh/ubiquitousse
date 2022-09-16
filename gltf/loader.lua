local json_decode -- ./gltf/loader.can:4
do -- ./gltf/loader.can:6
local r, json -- ./gltf/loader.can:6
r, json = pcall(require, "json") -- ./gltf/loader.can:6
if not r then -- ./gltf/loader.can:7
json = require((...):gsub("gltf%.loader$", "lib.json")) -- ./gltf/loader.can:7
end -- ./gltf/loader.can:7
json_decode = json["decode"] -- ./gltf/loader.can:8
end -- ./gltf/loader.can:8
local cpml -- ./gltf/loader.can:11
cpml = require("cpml") -- ./gltf/loader.can:11
local mat4, vec3, quat -- ./gltf/loader.can:12
mat4, vec3, quat = cpml["mat4"], cpml["vec3"], cpml["quat"] -- ./gltf/loader.can:12
local dunpack -- ./gltf/loader.can:14
dunpack = string["unpack"] or love["data"]["unpack"] -- ./gltf/loader.can:14
local attributeName -- ./gltf/loader.can:17
attributeName = { -- ./gltf/loader.can:17
["POSITION"] = "VertexPosition", -- ./gltf/loader.can:18
["NORMAL"] = "VertexNormal", -- ./gltf/loader.can:19
["TANGENT"] = "VertexTangent", -- ./gltf/loader.can:20
["TEXCOORD_0"] = "VertexTexCoord", -- ./gltf/loader.can:21
["TEXCOORD_1"] = "VertexTexCoord1", -- ./gltf/loader.can:22
["COLOR_0"] = "VertexColor", -- ./gltf/loader.can:23
["JOINTS_0"] = "VertexJoints", -- ./gltf/loader.can:24
["WEIGHTS_0"] = "VertexWeights" -- ./gltf/loader.can:25
} -- ./gltf/loader.can:25
local componentType -- ./gltf/loader.can:28
componentType = { -- ./gltf/loader.can:28
[5120] = "byte", -- ./gltf/loader.can:29
[5121] = "unsigned byte", -- ./gltf/loader.can:30
[5122] = "short", -- ./gltf/loader.can:31
[5123] = "unsigned short", -- ./gltf/loader.can:32
[5125] = "int", -- ./gltf/loader.can:33
[5126] = "float" -- ./gltf/loader.can:34
} -- ./gltf/loader.can:34
local samplerEnum -- ./gltf/loader.can:37
samplerEnum = { -- ./gltf/loader.can:37
[9728] = "nearest", -- ./gltf/loader.can:38
[9729] = "linear", -- ./gltf/loader.can:39
[9984] = "nearest_mipmap_nearest", -- ./gltf/loader.can:40
[9985] = "linear_mipmap_nearest", -- ./gltf/loader.can:41
[9986] = "nearest_mipmap_linear", -- ./gltf/loader.can:42
[9987] = "linear_mipmap_linear", -- ./gltf/loader.can:43
[33071] = "clamp", -- ./gltf/loader.can:44
[33648] = "mirroredrepeat", -- ./gltf/loader.can:45
[10497] = "repeat" -- ./gltf/loader.can:46
} -- ./gltf/loader.can:46
local mode -- ./gltf/loader.can:49
mode = { -- ./gltf/loader.can:49
[0] = "points", -- ./gltf/loader.can:50
[1] = "lines", -- ./gltf/loader.can:51
[2] = "line_loop", -- ./gltf/loader.can:52
[3] = "line_strip", -- ./gltf/loader.can:53
[4] = "triangles", -- ./gltf/loader.can:54
[5] = "strip", -- ./gltf/loader.can:55
[6] = "fan" -- ./gltf/loader.can:56
} -- ./gltf/loader.can:56
local gltf -- ./gltf/loader.can:77
gltf = function(path) -- ./gltf/loader.can:77
local f -- ./gltf/loader.can:78
f = assert(io["open"](path, "r")) -- ./gltf/loader.can:78
local t -- ./gltf/loader.can:79
t = json_decode(f:read("*a")) -- ./gltf/loader.can:79
f:close() -- ./gltf/loader.can:80
if t["asset"]["minVersion"] then -- ./gltf/loader.can:83
local maj, min -- ./gltf/loader.can:84
maj, min = t["asset"]["minVersion"]:match("^(%d+)%.(%d+)$") -- ./gltf/loader.can:84
assert(maj == "2" and min == "0", ("asset require at least glTF version %s.%s but we only support 2.0"):format(maj, min)) -- ./gltf/loader.can:85
else -- ./gltf/loader.can:85
local maj, min -- ./gltf/loader.can:87
maj, min = t["asset"]["version"]:match("^(%d+)%.(%d+)$") -- ./gltf/loader.can:87
assert(maj == "2", ("asset require glTF version %s.%s but we only support 2.x"):format(maj, min)) -- ./gltf/loader.can:88
end -- ./gltf/loader.can:88
t["nodes"] = t["nodes"] or ({}) -- ./gltf/loader.can:92
t["scenes"] = t["scenes"] or ({}) -- ./gltf/loader.can:93
t["cameras"] = t["cameras"] or ({}) -- ./gltf/loader.can:94
t["meshes"] = t["meshes"] or ({}) -- ./gltf/loader.can:95
t["buffers"] = t["buffers"] or ({}) -- ./gltf/loader.can:96
t["bufferViews"] = t["bufferViews"] or ({}) -- ./gltf/loader.can:97
t["accessors"] = t["accessors"] or ({}) -- ./gltf/loader.can:98
t["materials"] = t["materials"] or ({}) -- ./gltf/loader.can:99
t["textures"] = t["textures"] or ({}) -- ./gltf/loader.can:100
t["images"] = t["images"] or ({}) -- ./gltf/loader.can:101
t["samplers"] = t["samplers"] or ({}) -- ./gltf/loader.can:102
t["skins"] = t["skins"] or ({}) -- ./gltf/loader.can:103
t["animations"] = t["animations"] or ({}) -- ./gltf/loader.can:104
for _, scene in ipairs(t["scenes"]) do -- ./gltf/loader.can:107
if scene["name"] then -- ./gltf/loader.can:108
t["scenes"][scene["name"]] = scene -- ./gltf/loader.can:108
end -- ./gltf/loader.can:108
for i, node in ipairs(scene["nodes"]) do -- ./gltf/loader.can:109
scene["nodes"][i] = t["nodes"][node + 1] -- ./gltf/loader.can:110
if scene["nodes"][i]["name"] then -- ./gltf/loader.can:111
scene["nodes"][scene["nodes"][i]["name"]] = scene["nodes"][i] -- ./gltf/loader.can:111
end -- ./gltf/loader.can:111
end -- ./gltf/loader.can:111
end -- ./gltf/loader.can:111
if t["scene"] then -- ./gltf/loader.can:116
t["scene"] = t["scenes"][t["scene"] + 1] -- ./gltf/loader.can:117
end -- ./gltf/loader.can:117
for _, node in ipairs(t["nodes"]) do -- ./gltf/loader.can:121
if node["name"] then -- ./gltf/loader.can:122
t["nodes"][node["name"]] = node -- ./gltf/loader.can:122
end -- ./gltf/loader.can:122
node["children"] = node["children"] or ({}) -- ./gltf/loader.can:123
for i, child in ipairs(node["children"]) do -- ./gltf/loader.can:124
node["children"][i] = t["nodes"][child + 1] -- ./gltf/loader.can:125
end -- ./gltf/loader.can:125
if node["matrix"] then -- ./gltf/loader.can:127
node["matrix"] = mat4(node["matrix"]) -- ./gltf/loader.can:128
else -- ./gltf/loader.can:128
node["translation"] = node["translation"] or ({ -- ./gltf/loader.can:130
0, -- ./gltf/loader.can:130
0, -- ./gltf/loader.can:130
0 -- ./gltf/loader.can:130
}) -- ./gltf/loader.can:130
node["rotation"] = node["rotation"] or ({ -- ./gltf/loader.can:131
0, -- ./gltf/loader.can:131
0, -- ./gltf/loader.can:131
0, -- ./gltf/loader.can:131
1 -- ./gltf/loader.can:131
}) -- ./gltf/loader.can:131
node["scale"] = node["scale"] or ({ -- ./gltf/loader.can:132
1, -- ./gltf/loader.can:132
1, -- ./gltf/loader.can:132
1 -- ./gltf/loader.can:132
}) -- ./gltf/loader.can:132
node["translation"] = vec3(node["translation"]) -- ./gltf/loader.can:134
node["rotation"] = quat(node["rotation"]) -- ./gltf/loader.can:135
node["scale"] = vec3(node["scale"]) -- ./gltf/loader.can:136
node["matrix"] = mat4["identity"]() -- ./gltf/loader.can:139
node["matrix"]:scale(node["matrix"], node["scale"]) -- ./gltf/loader.can:140
node["matrix"]:mul(mat4["from_quaternion"](node["rotation"]), node["matrix"]) -- ./gltf/loader.can:141
node["matrix"]:translate(node["matrix"], node["translation"]) -- ./gltf/loader.can:142
end -- ./gltf/loader.can:142
if node["mesh"] then -- ./gltf/loader.can:144
node["mesh"] = t["meshes"][node["mesh"] + 1] -- ./gltf/loader.can:145
end -- ./gltf/loader.can:145
if node["camera"] then -- ./gltf/loader.can:147
node["camera"] = t["cameras"][node["camera"] + 1] -- ./gltf/loader.can:148
end -- ./gltf/loader.can:148
end -- ./gltf/loader.can:148
for i, buffer in ipairs(t["buffers"]) do -- ./gltf/loader.can:153
if i == 1 and not buffer["uri"] then -- ./gltf/loader.can:154
error("no support for glb-stored buffer") -- ./gltf/loader.can:155
end -- ./gltf/loader.can:155
if buffer["uri"]:match("data:") then -- ./gltf/loader.can:157
local data = buffer["uri"]:match("^data:.-,(.*)$") -- ./gltf/loader.can:158
if buffer["uri"]:match("^data:.-;base64,") then -- ./gltf/loader.can:159
buffer["data"] = love["data"]["decode"]("string", "base64", data):sub(1, buffer["byteLength"] + 1) -- ./gltf/loader.can:160
else -- ./gltf/loader.can:160
buffer["data"] = data:gsub("%%(%x%x)", function(hex) -- ./gltf/loader.can:162
return love["data"]["decode"]("string", "hex", hex) -- ./gltf/loader.can:163
end):sub(1, buffer["byteLength"] + 1) -- ./gltf/loader.can:164
end -- ./gltf/loader.can:164
else -- ./gltf/loader.can:164
local bf -- ./gltf/loader.can:167
bf = assert(io["open"](buffer["uri"], "r"), ("can't find ressource %s"):format(buffer["uri"])) -- ./gltf/loader.can:167
local s -- ./gltf/loader.can:168
s = bf:read("*a") -- ./gltf/loader.can:168
bf:close() -- ./gltf/loader.can:169
buffer["data"] = s:sub(1, buffer["byteLength"] + 1) -- ./gltf/loader.can:170
end -- ./gltf/loader.can:170
end -- ./gltf/loader.can:170
for _, view in ipairs(t["bufferViews"]) do -- ./gltf/loader.can:175
view["buffer"] = t["buffers"][view["buffer"] + 1] -- ./gltf/loader.can:176
view["byteOffset"] = view["byteOffset"] or (0) -- ./gltf/loader.can:177
end -- ./gltf/loader.can:177
for _, accessor in ipairs(t["accessors"]) do -- ./gltf/loader.can:182
accessor["bufferView"] = t["bufferViews"][accessor["bufferView"] + 1] -- ./gltf/loader.can:183
accessor["byteOffset"] = accessor["byteOffset"] or (0) -- ./gltf/loader.can:184
local view -- ./gltf/loader.can:186
view = accessor["bufferView"] -- ./gltf/loader.can:186
local data -- ./gltf/loader.can:187
data = view["buffer"]["data"] -- ./gltf/loader.can:187
local fmt, size -- ./gltf/loader.can:190
accessor["componentType"] = componentType[accessor["componentType"]] -- ./gltf/loader.can:191
if accessor["componentType"] == "byte" then -- ./gltf/loader.can:192
fmt, size = "b", 1 -- ./gltf/loader.can:193
elseif accessor["componentType"] == "unsigned byte" then -- ./gltf/loader.can:194
fmt, size = "B", 1 -- ./gltf/loader.can:195
elseif accessor["componentType"] == "short" then -- ./gltf/loader.can:196
fmt, size = "h", 2 -- ./gltf/loader.can:197
elseif accessor["componentType"] == "unsigned short" then -- ./gltf/loader.can:198
fmt, size = "H", 2 -- ./gltf/loader.can:199
elseif accessor["componentType"] == "unsigned int" then -- ./gltf/loader.can:200
fmt, size = "I4", 4 -- ./gltf/loader.can:201
elseif accessor["componentType"] == "float" then -- ./gltf/loader.can:202
fmt, size = "f", 4 -- ./gltf/loader.can:203
end -- ./gltf/loader.can:203
if accessor["type"] == "SCALAR" then -- ./gltf/loader.can:207
accessor["components"], fmt = 1, fmt -- ./gltf/loader.can:208
elseif accessor["type"] == "VEC2" then -- ./gltf/loader.can:209
accessor["components"], fmt = 2, fmt:rep(2) -- ./gltf/loader.can:210
elseif accessor["type"] == "VEC3" then -- ./gltf/loader.can:211
accessor["components"], fmt = 3, fmt:rep(3) -- ./gltf/loader.can:212
elseif accessor["type"] == "VEC4" then -- ./gltf/loader.can:213
accessor["components"], fmt = 4, fmt:rep(4) -- ./gltf/loader.can:214
elseif accessor["type"] == "MAT2" then -- ./gltf/loader.can:215
accessor["components"] = 4 -- ./gltf/loader.can:216
fmt = (fmt:rep(2) .. ("x"):rep(4 - (size * 2) % 4)):rep(2) -- ./gltf/loader.can:217
elseif accessor["type"] == "MAT3" then -- ./gltf/loader.can:218
accessor["components"] = 9 -- ./gltf/loader.can:219
fmt = (fmt:rep(3) .. ("x"):rep(4 - (size * 3) % 4)):rep(3) -- ./gltf/loader.can:220
elseif accessor["type"] == "MAT4" then -- ./gltf/loader.can:221
accessor["components"] = 16 -- ./gltf/loader.can:222
fmt = (fmt:rep(4) .. ("x"):rep(4 - (size * 4) % 4)):rep(4) -- ./gltf/loader.can:223
end -- ./gltf/loader.can:223
fmt = ("<") .. fmt -- ./gltf/loader.can:226
accessor["data"] = {} -- ./gltf/loader.can:229
local i -- ./gltf/loader.can:230
i = view["byteOffset"] + 1 + accessor["byteOffset"] -- ./gltf/loader.can:230
local stop -- ./gltf/loader.can:231
stop = view["byteOffset"] + 1 + view["byteLength"] -- ./gltf/loader.can:231
local count = 0 -- ./gltf/loader.can:232
while i < stop and count < accessor["count"] do -- ./gltf/loader.can:233
local d = { dunpack(fmt, data, i) } -- ./gltf/loader.can:234
d[# d] = nil -- ./gltf/loader.can:235
if accessor["components"] > 1 then -- ./gltf/loader.can:236
table["insert"](accessor["data"], d) -- ./gltf/loader.can:237
else -- ./gltf/loader.can:237
table["insert"](accessor["data"], d[1]) -- ./gltf/loader.can:239
end -- ./gltf/loader.can:239
count = count + (1) -- ./gltf/loader.can:241
i = i + (view["byteStride"] or (size * accessor["components"])) -- ./gltf/loader.can:242
end -- ./gltf/loader.can:242
end -- ./gltf/loader.can:242
for _, image in ipairs(t["images"]) do -- ./gltf/loader.can:249
if image["uri"] then -- ./gltf/loader.can:250
image["image"] = love["graphics"]["newImage"](image["uri"]) -- ./gltf/loader.can:251
else -- ./gltf/loader.can:251
image["bufferView"] = t["bufferViews"][image["bufferView"] + 1] -- ./gltf/loader.can:253
local view -- ./gltf/loader.can:255
view = image["bufferView"] -- ./gltf/loader.can:255
local data -- ./gltf/loader.can:256
data = view["buffer"]["data"] -- ./gltf/loader.can:256
image["data"] = love["image"]["newImageData"](love["data"]["newByteData"](data:sub(view["byteOffset"] + 1, view["byteOffset"] + view["byteLength"]))) -- ./gltf/loader.can:258
end -- ./gltf/loader.can:258
end -- ./gltf/loader.can:258
for _, sampler in ipairs(t["samplers"]) do -- ./gltf/loader.can:262
sampler["wrapS"] = sampler["wrapS"] or (10497) -- ./gltf/loader.can:263
sampler["wrapT"] = sampler["wrapT"] or (10497) -- ./gltf/loader.can:264
sampler["magFilter"] = samplerEnum[sampler["magFilter"]] -- ./gltf/loader.can:266
sampler["minFilter"] = samplerEnum[sampler["minFilter"]] -- ./gltf/loader.can:267
sampler["wrapS"] = samplerEnum[sampler["wrapS"]] -- ./gltf/loader.can:268
sampler["wrapT"] = samplerEnum[sampler["wrapT"]] -- ./gltf/loader.can:269
end -- ./gltf/loader.can:269
for _, texture in ipairs(t["textures"]) do -- ./gltf/loader.can:272
texture["source"] = t["images"][texture["source"] + 1] or {} -- ./gltf/loader.can:273
texture["sampler"] = t["samplers"][texture["sampler"] + 1] -- ./gltf/loader.can:274
local mag -- ./gltf/loader.can:276
mag = texture["sampler"]["magFilter"] -- ./gltf/loader.can:276
local min -- ./gltf/loader.can:277
min = texture["sampler"]["minFilter"] -- ./gltf/loader.can:277
local mip -- ./gltf/loader.can:278
if min:match("_mipmap_") then -- ./gltf/loader.can:279
min, mip = min:match("^(.*)_mipmap_(.*)$") -- ./gltf/loader.can:280
end -- ./gltf/loader.can:280
texture["image"] = love["graphics"]["newImage"](texture["source"]["data"], { ["mipmaps"] = not not mip }) -- ./gltf/loader.can:282
texture["image"]:setFilter(min or "linear", mag) -- ./gltf/loader.can:283
if mip then -- ./gltf/loader.can:284
texture["image"]:setMipmapFilter(mip) -- ./gltf/loader.can:284
end -- ./gltf/loader.can:284
texture["image"]:setWrap(texture["sampler"]["wrapS"], texture["sampler"]["wrapT"]) -- ./gltf/loader.can:285
end -- ./gltf/loader.can:285
t["materials"][0] = { -- ./gltf/loader.can:289
["pbrMetallicRoughness"] = { -- ./gltf/loader.can:290
["baseColorFactor"] = { -- ./gltf/loader.can:291
1, -- ./gltf/loader.can:291
1, -- ./gltf/loader.can:291
1, -- ./gltf/loader.can:291
1 -- ./gltf/loader.can:291
}, -- ./gltf/loader.can:291
["metallicFactor"] = 1, -- ./gltf/loader.can:292
["roughnessFactor"] = 1 -- ./gltf/loader.can:293
}, -- ./gltf/loader.can:293
["emissiveFactor"] = { -- ./gltf/loader.can:295
0, -- ./gltf/loader.can:295
0, -- ./gltf/loader.can:295
0 -- ./gltf/loader.can:295
}, -- ./gltf/loader.can:295
["alphaMode"] = "OPAQUE", -- ./gltf/loader.can:296
["alphaCutoff"] = .5, -- ./gltf/loader.can:297
["doubleSided"] = false -- ./gltf/loader.can:298
} -- ./gltf/loader.can:298
for _, material in ipairs(t["materials"]) do -- ./gltf/loader.can:301
material["pbrMetallicRoughness"] = material["pbrMetallicRoughness"] or ({}) -- ./gltf/loader.can:302
material["pbrMetallicRoughness"]["baseColorFactor"] = material["pbrMetallicRoughness"]["baseColorFactor"] or ({ -- ./gltf/loader.can:303
1, -- ./gltf/loader.can:303
1, -- ./gltf/loader.can:303
1, -- ./gltf/loader.can:303
1 -- ./gltf/loader.can:303
}) -- ./gltf/loader.can:303
if material["pbrMetallicRoughness"]["baseColorTexture"] then -- ./gltf/loader.can:304
material["pbrMetallicRoughness"]["baseColorTexture"]["index"] = t["textures"][material["pbrMetallicRoughness"]["baseColorTexture"]["index"] + 1] -- ./gltf/loader.can:305
material["pbrMetallicRoughness"]["baseColorTexture"]["texCoord"] = material["pbrMetallicRoughness"]["baseColorTexture"]["texCoord"] or (0) -- ./gltf/loader.can:306
end -- ./gltf/loader.can:306
material["pbrMetallicRoughness"]["metallicFactor"] = material["pbrMetallicRoughness"]["metallicFactor"] or (1) -- ./gltf/loader.can:308
material["pbrMetallicRoughness"]["roughnessFactor"] = material["pbrMetallicRoughness"]["roughnessFactor"] or (1) -- ./gltf/loader.can:309
if material["pbrMetallicRoughness"]["metallicRoughnessTexture"] then -- ./gltf/loader.can:310
material["pbrMetallicRoughness"]["metallicRoughnessTexture"]["index"] = t["textures"][material["pbrMetallicRoughness"]["metallicRoughnessTexture"]["index"] + 1] -- ./gltf/loader.can:311
material["pbrMetallicRoughness"]["metallicRoughnessTexture"]["texCoord"] = material["pbrMetallicRoughness"]["metallicRoughnessTexture"]["texCoord"] or (0) -- ./gltf/loader.can:312
end -- ./gltf/loader.can:312
if material["normalTexture"] then -- ./gltf/loader.can:314
material["normalTexture"]["index"] = t["textures"][material["normalTexture"]["index"] + 1] -- ./gltf/loader.can:315
material["normalTexture"]["texCoord"] = material["normalTexture"]["texCoord"] or (0) -- ./gltf/loader.can:316
material["normalTexture"]["scale"] = material["normalTexture"]["scale"] or (1) -- ./gltf/loader.can:317
end -- ./gltf/loader.can:317
if material["occlusionTexture"] then -- ./gltf/loader.can:319
material["occlusionTexture"]["index"] = t["textures"][material["occlusionTexture"]["index"] + 1] -- ./gltf/loader.can:320
material["occlusionTexture"]["texCoord"] = material["occlusionTexture"]["texCoord"] or (0) -- ./gltf/loader.can:321
material["occlusionTexture"]["strength"] = material["occlusionTexture"]["strength"] or (1) -- ./gltf/loader.can:322
end -- ./gltf/loader.can:322
if material["emissiveTexture"] then -- ./gltf/loader.can:324
material["emissiveTexture"]["index"] = t["textures"][material["emissiveTexture"]["index"] + 1] -- ./gltf/loader.can:325
material["emissiveTexture"]["texCoord"] = material["emissiveTexture"]["texCoord"] or (0) -- ./gltf/loader.can:326
end -- ./gltf/loader.can:326
material["emissiveFactor"] = material["emissiveFactor"] or ({ -- ./gltf/loader.can:328
0, -- ./gltf/loader.can:328
0, -- ./gltf/loader.can:328
0 -- ./gltf/loader.can:328
}) -- ./gltf/loader.can:328
material["alphaMode"] = material["alphaMode"] or ("OPAQUE") -- ./gltf/loader.can:329
material["alphaCutoff"] = material["alphaCutoff"] or (.5) -- ./gltf/loader.can:330
material["doubleSided"] = material["doubleSided"] or (false) -- ./gltf/loader.can:331
end -- ./gltf/loader.can:331
for _, mesh in ipairs(t["meshes"]) do -- ./gltf/loader.can:335
for _, primitive in ipairs(mesh["primitives"]) do -- ./gltf/loader.can:336
local vertexformat -- ./gltf/loader.can:337
vertexformat = {} -- ./gltf/loader.can:337
local vertices -- ./gltf/loader.can:338
vertices = {} -- ./gltf/loader.can:338
for n, v in pairs(primitive["attributes"]) do -- ./gltf/loader.can:339
local accessor -- ./gltf/loader.can:340
accessor = t["accessors"][v + 1] -- ./gltf/loader.can:340
primitive["attributes"][n] = accessor -- ./gltf/loader.can:341
table["insert"](vertexformat, { -- ./gltf/loader.can:342
attributeName[n] or n, -- ./gltf/loader.can:342
accessor["componentType"], -- ./gltf/loader.can:342
accessor["components"] -- ./gltf/loader.can:342
}) -- ./gltf/loader.can:342
for i, x in ipairs(accessor["data"]) do -- ./gltf/loader.can:343
local vertex -- ./gltf/loader.can:344
vertex = vertices[i] -- ./gltf/loader.can:344
if not vertex then -- ./gltf/loader.can:345
table["insert"](vertices, i, {}) -- ./gltf/loader.can:346
vertex = vertices[i] -- ./gltf/loader.can:347
end -- ./gltf/loader.can:347
for _, c in ipairs(x) do -- ./gltf/loader.can:349
table["insert"](vertex, c) -- ./gltf/loader.can:350
end -- ./gltf/loader.can:350
end -- ./gltf/loader.can:350
end -- ./gltf/loader.can:350
if primitive["mode"] then -- ./gltf/loader.can:355
primitive["mode"] = mode[primitive["mode"]] -- ./gltf/loader.can:356
else -- ./gltf/loader.can:356
primitive["mode"] = "triangles" -- ./gltf/loader.can:358
end -- ./gltf/loader.can:358
primitive["mesh"] = love["graphics"]["newMesh"](vertexformat, vertices, primitive["mode"]) -- ./gltf/loader.can:361
if primitive["indices"] then -- ./gltf/loader.can:362
primitive["indices"] = (function() -- ./gltf/loader.can:363
local self = {} -- ./gltf/loader.can:363
for _, i in ipairs(t["accessors"][primitive["indices"] + 1]["data"]) do -- ./gltf/loader.can:363
self[#self+1] = i + 1 -- ./gltf/loader.can:363
end -- ./gltf/loader.can:363
return self -- ./gltf/loader.can:363
end)() -- ./gltf/loader.can:363
primitive["mesh"]:setVertexMap(primitive["indices"]) -- ./gltf/loader.can:364
end -- ./gltf/loader.can:364
primitive["material"] = t["materials"][(primitive["material"] or - 1) + 1] -- ./gltf/loader.can:367
if primitive["material"]["pbrMetallicRoughness"]["baseColorTexture"] then -- ./gltf/loader.can:368
primitive["mesh"]:setTexture(primitive["material"]["pbrMetallicRoughness"]["baseColorTexture"]["index"]["image"]) -- ./gltf/loader.can:369
end -- ./gltf/loader.can:369
end -- ./gltf/loader.can:369
end -- ./gltf/loader.can:369
for _, camera in ipairs(t["cameras"]) do -- ./gltf/loader.can:377
if camera["name"] then -- ./gltf/loader.can:378
t["cameras"][camera["name"]] = camera -- ./gltf/loader.can:378
end -- ./gltf/loader.can:378
if camera["type"] == "perspective" then -- ./gltf/loader.can:379
camera["perspective"]["aspectRatio"] = camera["perspective"]["aspectRatio"] or (16 / 9) -- ./gltf/loader.can:380
camera["matrix"] = mat4["from_perspective"](camera["perspective"]["yfov"], camera["perspective"]["aspectRatio"], camera["perspective"]["znear"], camera["perspective"]["zfar"]) -- ./gltf/loader.can:381
elseif camera["type"] == "orthographic" then -- ./gltf/loader.can:382
camera["matrix"] = mat4["from_ortho"](0, 0, camera["orthographic"]["xmag"], camera["orthographic"]["ymag"], camera["orthographic"]["znear"], camera["orthographic"]["zfar"]) -- ./gltf/loader.can:383
end -- ./gltf/loader.can:383
end -- ./gltf/loader.can:383
return t -- ./gltf/loader.can:395
end -- ./gltf/loader.can:395
return gltf -- ./gltf/loader.can:398
