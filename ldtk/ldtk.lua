local lg -- ./ldtk/ldtk.can:38
lg = (love or {})["graphics"] -- ./ldtk/ldtk.can:38
local newQuad -- ./ldtk/ldtk.can:39
if lg then -- ./ldtk/ldtk.can:40
newQuad = lg["newQuad"] -- ./ldtk/ldtk.can:41
else -- ./ldtk/ldtk.can:41
newQuad = function(x, y, w, h, image) -- ./ldtk/ldtk.can:43
return { -- ./ldtk/ldtk.can:44
x, -- ./ldtk/ldtk.can:44
y, -- ./ldtk/ldtk.can:44
w, -- ./ldtk/ldtk.can:44
h -- ./ldtk/ldtk.can:44
} -- ./ldtk/ldtk.can:44
end -- ./ldtk/ldtk.can:44
end -- ./ldtk/ldtk.can:44
local json_decode -- ./ldtk/ldtk.can:49
json_decode = require((...):gsub("ldtk$", "json"))["decode"] -- ./ldtk/ldtk.can:49
local readJson -- ./ldtk/ldtk.can:50
readJson = function(file) -- ./ldtk/ldtk.can:50
local f -- ./ldtk/ldtk.can:51
f = assert(io["open"](file, "r")) -- ./ldtk/ldtk.can:51
local t = json_decode(f:read("*a")) -- ./ldtk/ldtk.can:52
f:close() -- ./ldtk/ldtk.can:53
return t -- ./ldtk/ldtk.can:54
end -- ./ldtk/ldtk.can:54
local parseColor -- ./ldtk/ldtk.can:58
parseColor = function(str) -- ./ldtk/ldtk.can:58
local r, g, b = str:match("^#(..)(..)(..)") -- ./ldtk/ldtk.can:59
r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) -- ./ldtk/ldtk.can:60
return { -- ./ldtk/ldtk.can:61
r / 255, -- ./ldtk/ldtk.can:61
g / 255, -- ./ldtk/ldtk.can:61
b / 255 -- ./ldtk/ldtk.can:61
} -- ./ldtk/ldtk.can:61
end -- ./ldtk/ldtk.can:61
local white -- ./ldtk/ldtk.can:63
white = { -- ./ldtk/ldtk.can:63
1, -- ./ldtk/ldtk.can:63
1, -- ./ldtk/ldtk.can:63
1 -- ./ldtk/ldtk.can:63
} -- ./ldtk/ldtk.can:63
local toLua -- ./ldtk/ldtk.can:66
toLua = function(type, val) -- ./ldtk/ldtk.can:66
if val == nil then -- ./ldtk/ldtk.can:67
return val -- ./ldtk/ldtk.can:67
end -- ./ldtk/ldtk.can:67
if type:match("^Array%<") then -- ./ldtk/ldtk.can:68
local itype = type:match("^Array%<(.*)%>$") -- ./ldtk/ldtk.can:69
for i, v in ipairs(val) do -- ./ldtk/ldtk.can:70
val[i] = toLua(itype, v) -- ./ldtk/ldtk.can:71
end -- ./ldtk/ldtk.can:71
elseif type == "Color" then -- ./ldtk/ldtk.can:73
return parseColor(val) -- ./ldtk/ldtk.can:74
elseif type == "Point" then -- ./ldtk/ldtk.can:75
return { -- ./ldtk/ldtk.can:76
["x"] = val["cx"], -- ./ldtk/ldtk.can:76
["y"] = val["cy"] -- ./ldtk/ldtk.can:76
} -- ./ldtk/ldtk.can:76
end -- ./ldtk/ldtk.can:76
return val -- ./ldtk/ldtk.can:78
end -- ./ldtk/ldtk.can:78
local getFields -- ./ldtk/ldtk.can:80
getFields = function(f) -- ./ldtk/ldtk.can:80
local t = {} -- ./ldtk/ldtk.can:81
for _, v in ipairs(f) do -- ./ldtk/ldtk.can:82
t[v["__identifier"]] = toLua(v["__type"], v["__value"]) -- ./ldtk/ldtk.can:83
end -- ./ldtk/ldtk.can:83
return t -- ./ldtk/ldtk.can:85
end -- ./ldtk/ldtk.can:85
local tileset_mt -- ./ldtk/ldtk.can:88
local make_cache -- ./ldtk/ldtk.can:91
make_cache = function(new_fn) -- ./ldtk/ldtk.can:91
return setmetatable({}, { -- ./ldtk/ldtk.can:92
["__mode"] = "v", -- ./ldtk/ldtk.can:93
["__call"] = function(cache, id) -- ./ldtk/ldtk.can:94
if not cache[id] then -- ./ldtk/ldtk.can:95
cache[id] = new_fn(id) -- ./ldtk/ldtk.can:96
end -- ./ldtk/ldtk.can:96
return cache[id] -- ./ldtk/ldtk.can:98
end -- ./ldtk/ldtk.can:98
}) -- ./ldtk/ldtk.can:98
end -- ./ldtk/ldtk.can:98
local cache -- ./ldtk/ldtk.can:102
cache = { -- ./ldtk/ldtk.can:102
["tileset"] = make_cache(function(tilesetDef) -- ./ldtk/ldtk.can:103
return tileset_mt["_init"](tilesetDef) -- ./ldtk/ldtk.can:104
end), -- ./ldtk/ldtk.can:104
["image"] = make_cache(function(path) -- ./ldtk/ldtk.can:106
if lg then -- ./ldtk/ldtk.can:107
return lg["newImage"](path) -- ./ldtk/ldtk.can:108
else -- ./ldtk/ldtk.can:108
return path -- ./ldtk/ldtk.can:110
end -- ./ldtk/ldtk.can:110
end) -- ./ldtk/ldtk.can:110
} -- ./ldtk/ldtk.can:110
tileset_mt = { -- ./ldtk/ldtk.can:118
["_newQuad"] = function(self, x, y, width, height) -- ./ldtk/ldtk.can:119
return newQuad(x, y, width, height, self["image"]) -- ./ldtk/ldtk.can:120
end, -- ./ldtk/ldtk.can:120
["_getTileQuad"] = function(self, tileid, x, y, size) -- ./ldtk/ldtk.can:122
if not self["_tileQuads"][tileid] then -- ./ldtk/ldtk.can:123
self["_tileQuads"][tileid] = self:_newQuad(x, y, size, size) -- ./ldtk/ldtk.can:124
end -- ./ldtk/ldtk.can:124
return self["_tileQuads"][tileid] -- ./ldtk/ldtk.can:126
end, -- ./ldtk/ldtk.can:126
["_init"] = function(tilesetDef) -- ./ldtk/ldtk.can:128
local t = { -- ./ldtk/ldtk.can:129
["image"] = cache["image"](tilesetDef["path"]), -- ./ldtk/ldtk.can:132
["_tileQuads"] = {} -- ./ldtk/ldtk.can:134
} -- ./ldtk/ldtk.can:134
return setmetatable(t, tileset_mt) -- ./ldtk/ldtk.can:136
end -- ./ldtk/ldtk.can:136
} -- ./ldtk/ldtk.can:136
tileset_mt["__index"] = tileset_mt -- ./ldtk/ldtk.can:139
local layer_mt -- ./ldtk/ldtk.can:146
layer_mt = { -- ./ldtk/ldtk.can:146
["draw"] = function(self, x, y) -- ./ldtk/ldtk.can:154
if x == nil then x = 0 end -- ./ldtk/ldtk.can:154
if y == nil then y = 0 end -- ./ldtk/ldtk.can:154
if self["visible"] then -- ./ldtk/ldtk.can:155
lg["push"]() -- ./ldtk/ldtk.can:156
lg["translate"](x + self["x"], y + self["y"]) -- ./ldtk/ldtk.can:157
if self["spritebatch"] then -- ./ldtk/ldtk.can:158
lg["setColor"](1, 1, 1, self["opacity"]) -- ./ldtk/ldtk.can:159
lg["draw"](self["spritebatch"]) -- ./ldtk/ldtk.can:160
elseif self["intTiles"] then -- ./ldtk/ldtk.can:161
for _, t in ipairs(self["intTiles"]) do -- ./ldtk/ldtk.can:162
lg["setColor"](t["color"]) -- ./ldtk/ldtk.can:163
lg["rectangle"]("fill", t["x"], t["y"], t["layer"]["gridSize"], t["layer"]["gridSize"]) -- ./ldtk/ldtk.can:164
end -- ./ldtk/ldtk.can:164
elseif self["entities"] then -- ./ldtk/ldtk.can:166
for _, e in ipairs(self["entities"]) do -- ./ldtk/ldtk.can:167
if e["draw"] then -- ./ldtk/ldtk.can:168
e:draw() -- ./ldtk/ldtk.can:168
end -- ./ldtk/ldtk.can:168
end -- ./ldtk/ldtk.can:168
end -- ./ldtk/ldtk.can:168
lg["pop"]() -- ./ldtk/ldtk.can:171
end -- ./ldtk/ldtk.can:171
end, -- ./ldtk/ldtk.can:171
["_unloadCallbacks"] = function(self, callbacks) -- ./ldtk/ldtk.can:175
local onRemoveTile = callbacks["onRemoveTile"] -- ./ldtk/ldtk.can:176
if self["tiles"] and onRemoveTile then -- ./ldtk/ldtk.can:177
for _, t in ipairs(self["tiles"]) do -- ./ldtk/ldtk.can:178
onRemoveTile(t) -- ./ldtk/ldtk.can:179
end -- ./ldtk/ldtk.can:179
end -- ./ldtk/ldtk.can:179
local onRemoveIntTile = callbacks["onRemoveIntTile"] -- ./ldtk/ldtk.can:182
if self["intTiles"] and onRemoveIntTile then -- ./ldtk/ldtk.can:183
for _, t in ipairs(self["intTiles"]) do -- ./ldtk/ldtk.can:184
onRemoveIntTile(t) -- ./ldtk/ldtk.can:185
end -- ./ldtk/ldtk.can:185
end -- ./ldtk/ldtk.can:185
local onRemoveEntity = callbacks["onRemoveEntity"] -- ./ldtk/ldtk.can:188
if self["entities"] and onRemoveEntity then -- ./ldtk/ldtk.can:189
for _, e in ipairs(self["entities"]) do -- ./ldtk/ldtk.can:190
onRemoveEntity(e) -- ./ldtk/ldtk.can:191
end -- ./ldtk/ldtk.can:191
end -- ./ldtk/ldtk.can:191
end, -- ./ldtk/ldtk.can:191
["_init"] = function(layer, level, order, callbacks) -- ./ldtk/ldtk.can:195
local gridSize -- ./ldtk/ldtk.can:196
gridSize = layer["__gridSize"] -- ./ldtk/ldtk.can:196
local t -- ./ldtk/ldtk.can:197
t = { -- ./ldtk/ldtk.can:197
["level"] = level, -- ./ldtk/ldtk.can:200
["identifier"] = layer["__identifier"], -- ./ldtk/ldtk.can:203
["type"] = layer["__type"], -- ./ldtk/ldtk.can:206
["visible"] = layer["visible"], -- ./ldtk/ldtk.can:209
["opacity"] = layer["opacity"], -- ./ldtk/ldtk.can:212
["order"] = order, -- ./ldtk/ldtk.can:215
["x"] = layer["__pxTotalOffsetX"], -- ./ldtk/ldtk.can:218
["y"] = layer["__pxTotalOffsetY"], -- ./ldtk/ldtk.can:221
["gridSize"] = gridSize, -- ./ldtk/ldtk.can:224
["gridWidth"] = layer["__cWid"], -- ./ldtk/ldtk.can:227
["gridHeight"] = layer["__cHei"], -- ./ldtk/ldtk.can:230
["entities"] = nil, -- ./ldtk/ldtk.can:233
["tiles"] = nil, -- ./ldtk/ldtk.can:237
["tileset"] = nil, -- ./ldtk/ldtk.can:241
["spritebatch"] = nil, -- ./ldtk/ldtk.can:246
["intTiles"] = nil -- ./ldtk/ldtk.can:250
} -- ./ldtk/ldtk.can:250
if layer["__tilesetDefUid"] then -- ./ldtk/ldtk.can:253
t["tiles"] = {} -- ./ldtk/ldtk.can:254
local tilesetData = level["project"]["_tilesetData"][layer["__tilesetDefUid"]] -- ./ldtk/ldtk.can:255
t["tileset"] = cache["tileset"](tilesetData) -- ./ldtk/ldtk.can:256
local tiles = layer["__type"] == "Tiles" and layer["gridTiles"] or layer["autoLayerTiles"] -- ./ldtk/ldtk.can:257
local onAddTile = callbacks["onAddTile"] -- ./ldtk/ldtk.can:258
if lg then -- ./ldtk/ldtk.can:259
t["spritebatch"] = lg["newSpriteBatch"](t["tileset"]["image"]) -- ./ldtk/ldtk.can:259
end -- ./ldtk/ldtk.can:259
for _, tl in ipairs(tiles) do -- ./ldtk/ldtk.can:260
local quad -- ./ldtk/ldtk.can:261
quad = t["tileset"]:_getTileQuad(tl["t"], tl["src"][1], tl["src"][2], gridSize) -- ./ldtk/ldtk.can:261
local sx, sy = 1, 1 -- ./ldtk/ldtk.can:262
local x, y -- ./ldtk/ldtk.can:263
x, y = tl["px"][1], tl["px"][2] -- ./ldtk/ldtk.can:263
local tile -- ./ldtk/ldtk.can:271
tile = { -- ./ldtk/ldtk.can:271
["layer"] = t, -- ./ldtk/ldtk.can:274
["x"] = x, -- ./ldtk/ldtk.can:277
["y"] = y, -- ./ldtk/ldtk.can:280
["flipX"] = false, -- ./ldtk/ldtk.can:283
["flipY"] = false, -- ./ldtk/ldtk.can:286
["tags"] = tilesetData[tl["t"]]["tags"], -- ./ldtk/ldtk.can:289
["data"] = tilesetData[tl["t"]]["data"], -- ./ldtk/ldtk.can:292
["quad"] = quad -- ./ldtk/ldtk.can:296
} -- ./ldtk/ldtk.can:296
if tl["f"] == 1 or tl["f"] == 3 then -- ./ldtk/ldtk.can:298
sx = - 1 -- ./ldtk/ldtk.can:299
x = x + (gridSize) -- ./ldtk/ldtk.can:300
tile["flipX"] = true -- ./ldtk/ldtk.can:301
end -- ./ldtk/ldtk.can:301
if tl["f"] == 2 or tl["f"] == 3 then -- ./ldtk/ldtk.can:303
sy = - 1 -- ./ldtk/ldtk.can:304
y = y + (gridSize) -- ./ldtk/ldtk.can:305
tile["flipY"] = true -- ./ldtk/ldtk.can:306
end -- ./ldtk/ldtk.can:306
if t["spritebatch"] then -- ./ldtk/ldtk.can:308
t["spritebatch"]:add(quad, x, y, 0, sx, sy) -- ./ldtk/ldtk.can:308
end -- ./ldtk/ldtk.can:308
table["insert"](t["tiles"], tile) -- ./ldtk/ldtk.can:309
if onAddTile then -- ./ldtk/ldtk.can:310
onAddTile(tile) -- ./ldtk/ldtk.can:310
end -- ./ldtk/ldtk.can:310
end -- ./ldtk/ldtk.can:310
elseif layer["__type"] == "IntGrid" then -- ./ldtk/ldtk.can:313
t["intTiles"] = {} -- ./ldtk/ldtk.can:314
local onAddIntTile = callbacks["onAddIntTile"] -- ./ldtk/ldtk.can:315
local values = level["project"]["_layerDef"][layer["layerDefUid"]]["intGridValues"] -- ./ldtk/ldtk.can:316
for i, tl in ipairs(layer["intGridCsv"]) do -- ./ldtk/ldtk.can:317
if tl > 0 then -- ./ldtk/ldtk.can:318
local y -- ./ldtk/ldtk.can:319
y = math["floor"]((i - 1) / t["gridWidth"]) * gridSize -- ./ldtk/ldtk.can:319
local x -- ./ldtk/ldtk.can:320
x = ((i - 1) % t["gridWidth"]) * gridSize -- ./ldtk/ldtk.can:320
local tile -- ./ldtk/ldtk.can:328
tile = { -- ./ldtk/ldtk.can:328
["layer"] = t, -- ./ldtk/ldtk.can:331
["x"] = x, -- ./ldtk/ldtk.can:334
["y"] = y, -- ./ldtk/ldtk.can:337
["identifier"] = values[tl]["identifier"], -- ./ldtk/ldtk.can:340
["value"] = tl, -- ./ldtk/ldtk.can:343
["color"] = values[tl]["color"] -- ./ldtk/ldtk.can:346
} -- ./ldtk/ldtk.can:346
table["insert"](t["intTiles"], tile) -- ./ldtk/ldtk.can:348
if onAddIntTile then -- ./ldtk/ldtk.can:349
onAddIntTile(tile) -- ./ldtk/ldtk.can:349
end -- ./ldtk/ldtk.can:349
end -- ./ldtk/ldtk.can:349
end -- ./ldtk/ldtk.can:349
end -- ./ldtk/ldtk.can:349
if layer["__type"] == "Entities" then -- ./ldtk/ldtk.can:354
t["entities"] = {} -- ./ldtk/ldtk.can:355
local onAddEntity = callbacks["onAddEntity"] -- ./ldtk/ldtk.can:356
for _, e in ipairs(layer["entityInstances"]) do -- ./ldtk/ldtk.can:357
local entityDef -- ./ldtk/ldtk.can:358
entityDef = level["project"]["_entityData"][e["defUid"]] -- ./ldtk/ldtk.can:358
local entity -- ./ldtk/ldtk.can:366
entity = { -- ./ldtk/ldtk.can:366
["layer"] = t, -- ./ldtk/ldtk.can:369
["identifier"] = e["__identifier"], -- ./ldtk/ldtk.can:372
["x"] = e["px"][1], -- ./ldtk/ldtk.can:375
["y"] = e["px"][2], -- ./ldtk/ldtk.can:378
["width"] = e["width"], -- ./ldtk/ldtk.can:381
["height"] = e["height"], -- ./ldtk/ldtk.can:384
["sx"] = e["width"] / entityDef["width"], -- ./ldtk/ldtk.can:387
["sy"] = e["height"] / entityDef["height"], -- ./ldtk/ldtk.can:390
["pivotX"] = e["__pivot"][1] * e["width"], -- ./ldtk/ldtk.can:393
["pivotY"] = e["__pivot"][2] * e["height"], -- ./ldtk/ldtk.can:396
["color"] = entityDef["color"], -- ./ldtk/ldtk.can:399
["tile"] = nil, -- ./ldtk/ldtk.can:403
["fields"] = getFields(e["fieldInstances"]), -- ./ldtk/ldtk.can:406
["draw"] = function(self) -- ./ldtk/ldtk.can:412
if self["tile"] then -- ./ldtk/ldtk.can:413
local _, _, w, h -- ./ldtk/ldtk.can:414
_, _, w, h = self["tile"]["quad"]:getViewport() -- ./ldtk/ldtk.can:414
lg["setColor"](white) -- ./ldtk/ldtk.can:415
lg["draw"](self["tile"]["tileset"]["image"], self["tile"]["quad"], self["x"] - self["pivotX"], self["y"] - self["pivotY"], 0, self["width"] / w, self["height"] / h) -- ./ldtk/ldtk.can:416
else -- ./ldtk/ldtk.can:416
lg["setColor"](self["color"]) -- ./ldtk/ldtk.can:418
lg["rectangle"]("line", self["x"] - self["pivotX"], self["y"] - self["pivotY"], self["width"], self["height"]) -- ./ldtk/ldtk.can:419
end -- ./ldtk/ldtk.can:419
end -- ./ldtk/ldtk.can:419
} -- ./ldtk/ldtk.can:419
if e["__tile"] then -- ./ldtk/ldtk.can:423
local tileset = cache["tileset"](level["project"]["_tilesetData"][e["__tile"]["tilesetUid"]]) -- ./ldtk/ldtk.can:424
local srcRect = e["__tile"]["srcRect"] -- ./ldtk/ldtk.can:425
local quad = tileset:_newQuad(srcRect[1], srcRect[2], srcRect[3], srcRect[4]) -- ./ldtk/ldtk.can:426
entity["tile"] = { -- ./ldtk/ldtk.can:427
["tileset"] = tileset, -- ./ldtk/ldtk.can:428
["quad"] = quad -- ./ldtk/ldtk.can:429
} -- ./ldtk/ldtk.can:429
end -- ./ldtk/ldtk.can:429
table["insert"](t["entities"], entity) -- ./ldtk/ldtk.can:432
if onAddEntity then -- ./ldtk/ldtk.can:433
onAddEntity(entity) -- ./ldtk/ldtk.can:433
end -- ./ldtk/ldtk.can:433
end -- ./ldtk/ldtk.can:433
end -- ./ldtk/ldtk.can:433
return setmetatable(t, layer_mt) -- ./ldtk/ldtk.can:436
end -- ./ldtk/ldtk.can:436
} -- ./ldtk/ldtk.can:436
layer_mt["__index"] = layer_mt -- ./ldtk/ldtk.can:439
local level_mt -- ./ldtk/ldtk.can:448
level_mt = { -- ./ldtk/ldtk.can:448
["draw"] = function(self, x, y) -- ./ldtk/ldtk.can:459
if x == nil then x = 0 end -- ./ldtk/ldtk.can:459
if y == nil then y = 0 end -- ./ldtk/ldtk.can:459
assert(self["loaded"] == true, "level not loaded") -- ./ldtk/ldtk.can:460
lg["push"]() -- ./ldtk/ldtk.can:461
lg["translate"](x + self["x"], y + self["y"]) -- ./ldtk/ldtk.can:462
self:drawBackground() -- ./ldtk/ldtk.can:463
for _, l in ipairs(self["layers"]) do -- ./ldtk/ldtk.can:465
l:draw() -- ./ldtk/ldtk.can:466
end -- ./ldtk/ldtk.can:466
lg["pop"]() -- ./ldtk/ldtk.can:468
end, -- ./ldtk/ldtk.can:468
["drawBackground"] = function(self, x, y) -- ./ldtk/ldtk.can:479
if x == nil then x = 0 end -- ./ldtk/ldtk.can:479
if y == nil then y = 0 end -- ./ldtk/ldtk.can:479
assert(self["loaded"] == true, "level not loaded") -- ./ldtk/ldtk.can:480
lg["setColor"](self["background"]["color"]) -- ./ldtk/ldtk.can:482
lg["rectangle"]("fill", x, y, self["width"], self["height"]) -- ./ldtk/ldtk.can:483
lg["setColor"](white) -- ./ldtk/ldtk.can:485
local bgImage -- ./ldtk/ldtk.can:486
bgImage = self["background"]["image"] -- ./ldtk/ldtk.can:486
if bgImage then -- ./ldtk/ldtk.can:487
lg["draw"](bgImage["image"], bgImage["quad"], x + bgImage["x"], y + bgImage["y"], 0, bgImage["sx"], bgImage["sy"]) -- ./ldtk/ldtk.can:488
end -- ./ldtk/ldtk.can:488
end, -- ./ldtk/ldtk.can:488
["load"] = function(self, callbacks) -- ./ldtk/ldtk.can:506
if callbacks == nil then callbacks = {} end -- ./ldtk/ldtk.can:506
assert(self["loaded"] == false, "level already loaded") -- ./ldtk/ldtk.can:507
if self["_json"]["bgRelPath"] then -- ./ldtk/ldtk.can:508
local pos -- ./ldtk/ldtk.can:509
pos = self["_json"]["__bgPos"] -- ./ldtk/ldtk.can:509
local cropRect -- ./ldtk/ldtk.can:510
cropRect = pos["cropRect"] -- ./ldtk/ldtk.can:510
local image -- ./ldtk/ldtk.can:511
image = cache["image"](self["project"]["_directory"] .. self["_json"]["bgRelPath"]) -- ./ldtk/ldtk.can:511
self["background"]["image"] = { -- ./ldtk/ldtk.can:512
["image"] = image, -- ./ldtk/ldtk.can:513
["quad"] = newQuad(cropRect[1], cropRect[2], cropRect[3], cropRect[4], image), -- ./ldtk/ldtk.can:514
["x"] = pos["topLeftPx"][1], -- ./ldtk/ldtk.can:515
["y"] = pos["topLeftPx"][2], -- ./ldtk/ldtk.can:516
["sx"] = pos["scale"][1], -- ./ldtk/ldtk.can:517
["sy"] = pos["scale"][1] -- ./ldtk/ldtk.can:518
} -- ./ldtk/ldtk.can:518
end -- ./ldtk/ldtk.can:518
local layerInstances -- ./ldtk/ldtk.can:521
if self["_json"]["externalRelPath"] then -- ./ldtk/ldtk.can:522
layerInstances = readJson(self["project"]["_directory"] .. self["_json"]["externalRelPath"])["layerInstances"] -- ./ldtk/ldtk.can:523
else -- ./ldtk/ldtk.can:523
layerInstances = self["_json"]["layerInstances"] -- ./ldtk/ldtk.can:525
end -- ./ldtk/ldtk.can:525
self["layers"] = {} -- ./ldtk/ldtk.can:527
local onAddLayer -- ./ldtk/ldtk.can:528
onAddLayer = callbacks["onAddLayer"] -- ./ldtk/ldtk.can:528
for i = # layerInstances, 1, - 1 do -- ./ldtk/ldtk.can:529
local layer = layer_mt["_init"](layerInstances[i], self, i, callbacks) -- ./ldtk/ldtk.can:530
table["insert"](self["layers"], layer) -- ./ldtk/ldtk.can:531
if onAddLayer then -- ./ldtk/ldtk.can:532
onAddLayer(layer) -- ./ldtk/ldtk.can:532
end -- ./ldtk/ldtk.can:532
end -- ./ldtk/ldtk.can:532
self["loaded"] = true -- ./ldtk/ldtk.can:534
end, -- ./ldtk/ldtk.can:534
["unload"] = function(self, callbacks) -- ./ldtk/ldtk.can:547
if callbacks == nil then callbacks = {} end -- ./ldtk/ldtk.can:547
assert(self["loaded"] == true, "level not loaded") -- ./ldtk/ldtk.can:548
local onRemoveLayer -- ./ldtk/ldtk.can:549
onRemoveLayer = callbacks["onRemoveLayer"] -- ./ldtk/ldtk.can:549
for _, l in ipairs(self["layers"]) do -- ./ldtk/ldtk.can:550
l:_unloadCallbacks(callbacks) -- ./ldtk/ldtk.can:551
if onRemoveLayer then -- ./ldtk/ldtk.can:552
onRemoveLayer(l) -- ./ldtk/ldtk.can:552
end -- ./ldtk/ldtk.can:552
end -- ./ldtk/ldtk.can:552
self["loaded"] = false -- ./ldtk/ldtk.can:554
self["background"]["image"] = nil -- ./ldtk/ldtk.can:555
self["layers"] = nil -- ./ldtk/ldtk.can:556
end, -- ./ldtk/ldtk.can:556
["_init"] = function(level, project) -- ./ldtk/ldtk.can:559
local t -- ./ldtk/ldtk.can:560
t = { -- ./ldtk/ldtk.can:560
["project"] = project, -- ./ldtk/ldtk.can:563
["loaded"] = false, -- ./ldtk/ldtk.can:566
["identifier"] = level["identifier"], -- ./ldtk/ldtk.can:569
["x"] = level["worldX"], -- ./ldtk/ldtk.can:572
["y"] = level["worldY"], -- ./ldtk/ldtk.can:575
["width"] = level["pxWid"], -- ./ldtk/ldtk.can:578
["height"] = level["pxHei"], -- ./ldtk/ldtk.can:581
["fields"] = getFields(level["fieldInstances"]), -- ./ldtk/ldtk.can:584
["layers"] = nil, -- ./ldtk/ldtk.can:587
["background"] = { -- ./ldtk/ldtk.can:595
["color"] = parseColor(level["__bgColor"]), -- ./ldtk/ldtk.can:596
["image"] = nil -- ./ldtk/ldtk.can:597
}, -- ./ldtk/ldtk.can:597
["_json"] = level -- ./ldtk/ldtk.can:601
} -- ./ldtk/ldtk.can:601
return setmetatable(t, level_mt) -- ./ldtk/ldtk.can:603
end -- ./ldtk/ldtk.can:603
} -- ./ldtk/ldtk.can:603
level_mt["__index"] = level_mt -- ./ldtk/ldtk.can:606
local project_mt -- ./ldtk/ldtk.can:613
project_mt = { ["_init"] = function(project, directory) -- ./ldtk/ldtk.can:614
assert(project["jsonVersion"] == "0.9.3", ("the map was made with LDtk version %s but the importer is made for 0.9.3"):format(project["jsonVersion"])) -- ./ldtk/ldtk.can:615
local t -- ./ldtk/ldtk.can:616
t = { -- ./ldtk/ldtk.can:616
["levels"] = nil, -- ./ldtk/ldtk.can:619
["_directory"] = directory, -- ./ldtk/ldtk.can:622
["_layerDef"] = nil, -- ./ldtk/ldtk.can:623
["_tilesetData"] = nil, -- ./ldtk/ldtk.can:624
["_entityData"] = nil -- ./ldtk/ldtk.can:625
} -- ./ldtk/ldtk.can:625
t["levels"] = (function() -- ./ldtk/ldtk.can:627
local self = {} -- ./ldtk/ldtk.can:627
for _, lvl in ipairs(project["levels"]) do -- ./ldtk/ldtk.can:628
do -- ./ldtk/ldtk.can:629
local __CAN_a = table.pack(level_mt["_init"](lvl, t)) -- ./ldtk/ldtk.can:629
table.move(__CAN_a, 1, __CAN_a.n, #self+1, self) -- ./ldtk/ldtk.can:629
end -- ./ldtk/ldtk.can:629
end -- ./ldtk/ldtk.can:629
return self -- ./ldtk/ldtk.can:629
end)() -- ./ldtk/ldtk.can:629
t["_tilesetData"] = (function() -- ./ldtk/ldtk.can:632
local self = {} -- ./ldtk/ldtk.can:632
for _, ts in ipairs(project["defs"]["tilesets"]) do -- ./ldtk/ldtk.can:633
self[ts["uid"]] = { ["path"] = directory .. ts["relPath"] } -- ./ldtk/ldtk.can:635
local tilesetData = self[ts["uid"]] -- ./ldtk/ldtk.can:637
for gridx = 0, ts["__cWid"] - 1 do -- ./ldtk/ldtk.can:638
for gridy = 0, ts["__cHei"] - 1 do -- ./ldtk/ldtk.can:639
tilesetData[gridx + gridy * ts["__cWid"]] = { -- ./ldtk/ldtk.can:640
["tags"] = {}, -- ./ldtk/ldtk.can:641
["data"] = nil -- ./ldtk/ldtk.can:642
} -- ./ldtk/ldtk.can:642
end -- ./ldtk/ldtk.can:642
end -- ./ldtk/ldtk.can:642
for _, custom in ipairs(ts["customData"]) do -- ./ldtk/ldtk.can:646
tilesetData[custom["tileId"]]["data"] = custom["data"] -- ./ldtk/ldtk.can:647
end -- ./ldtk/ldtk.can:647
for _, tag in ipairs(ts["enumTags"]) do -- ./ldtk/ldtk.can:649
local value = tag["enumValueId"] -- ./ldtk/ldtk.can:650
for _, tileId in ipairs(tag["tileIds"]) do -- ./ldtk/ldtk.can:651
table["insert"](tilesetData[tileId]["tags"], value) -- ./ldtk/ldtk.can:652
tilesetData[tileId]["tags"][value] = true -- ./ldtk/ldtk.can:653
end -- ./ldtk/ldtk.can:653
end -- ./ldtk/ldtk.can:653
end -- ./ldtk/ldtk.can:653
return self -- ./ldtk/ldtk.can:653
end)() -- ./ldtk/ldtk.can:653
t["_layerDef"] = (function() -- ./ldtk/ldtk.can:658
local self = {} -- ./ldtk/ldtk.can:658
for _, lay in ipairs(project["defs"]["layers"]) do -- ./ldtk/ldtk.can:659
self[lay["uid"]] = { ["intGridValues"] = nil } -- ./ldtk/ldtk.can:661
local layerDef = self[lay["uid"]] -- ./ldtk/ldtk.can:663
if lay["__type"] == "IntGrid" then -- ./ldtk/ldtk.can:664
layerDef["intGridValues"] = (function() -- ./ldtk/ldtk.can:665
local self = {} -- ./ldtk/ldtk.can:665
for _, v in ipairs(lay["intGridValues"]) do -- ./ldtk/ldtk.can:666
self[v["value"]] = { -- ./ldtk/ldtk.can:667
["color"] = parseColor(v["color"]), -- ./ldtk/ldtk.can:668
["identifier"] = v["identifier"] -- ./ldtk/ldtk.can:669
} -- ./ldtk/ldtk.can:669
end -- ./ldtk/ldtk.can:669
return self -- ./ldtk/ldtk.can:669
end)() -- ./ldtk/ldtk.can:669
end -- ./ldtk/ldtk.can:669
end -- ./ldtk/ldtk.can:669
return self -- ./ldtk/ldtk.can:669
end)() -- ./ldtk/ldtk.can:669
t["_entityData"] = (function() -- ./ldtk/ldtk.can:676
local self = {} -- ./ldtk/ldtk.can:676
for _, ent in ipairs(project["defs"]["entities"]) do -- ./ldtk/ldtk.can:677
self[ent["uid"]] = { -- ./ldtk/ldtk.can:678
["color"] = parseColor(ent["color"]), -- ./ldtk/ldtk.can:679
["width"] = ent["width"], -- ./ldtk/ldtk.can:680
["height"] = ent["height"] -- ./ldtk/ldtk.can:681
} -- ./ldtk/ldtk.can:681
end -- ./ldtk/ldtk.can:681
return self -- ./ldtk/ldtk.can:681
end)() -- ./ldtk/ldtk.can:681
return setmetatable(t, project_mt) -- ./ldtk/ldtk.can:685
end } -- ./ldtk/ldtk.can:685
project_mt["__index"] = project_mt -- ./ldtk/ldtk.can:688
return function(file) -- ./ldtk/ldtk.can:719
return project_mt["_init"](readJson(file), file:match("^(.-)[^%/%\\]+$")) -- ./ldtk/ldtk.can:720
end -- ./ldtk/ldtk.can:720
