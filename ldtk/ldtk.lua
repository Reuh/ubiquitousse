local lg -- ./ldtk/ldtk.can:47
lg = (love or {})["graphics"] -- ./ldtk/ldtk.can:47
local newQuad -- ./ldtk/ldtk.can:48
if lg then -- ./ldtk/ldtk.can:49
newQuad = lg["newQuad"] -- ./ldtk/ldtk.can:50
else -- ./ldtk/ldtk.can:50
newQuad = function(x, y, w, h, image) -- ./ldtk/ldtk.can:52
return { -- ./ldtk/ldtk.can:53
x, -- ./ldtk/ldtk.can:53
y, -- ./ldtk/ldtk.can:53
w, -- ./ldtk/ldtk.can:53
h -- ./ldtk/ldtk.can:53
} -- ./ldtk/ldtk.can:53
end -- ./ldtk/ldtk.can:53
end -- ./ldtk/ldtk.can:53
local cache -- ./ldtk/ldtk.can:57
local json_decode -- ./ldtk/ldtk.can:60
do -- ./ldtk/ldtk.can:62
local r, json -- ./ldtk/ldtk.can:62
r, json = pcall(require, "json") -- ./ldtk/ldtk.can:62
if not r then -- ./ldtk/ldtk.can:63
json = require((...):gsub("ldtk%.ldtk$", "lib.json")) -- ./ldtk/ldtk.can:63
end -- ./ldtk/ldtk.can:63
json_decode = json["decode"] -- ./ldtk/ldtk.can:64
end -- ./ldtk/ldtk.can:64
local readJson -- ./ldtk/ldtk.can:66
readJson = function(file) -- ./ldtk/ldtk.can:66
local f -- ./ldtk/ldtk.can:67
f = assert(io["open"](file, "r")) -- ./ldtk/ldtk.can:67
local t = json_decode(f:read("*a")) -- ./ldtk/ldtk.can:68
f:close() -- ./ldtk/ldtk.can:69
return t -- ./ldtk/ldtk.can:70
end -- ./ldtk/ldtk.can:70
local parseColor -- ./ldtk/ldtk.can:74
parseColor = function(str) -- ./ldtk/ldtk.can:74
local r, g, b = str:match("^#(..)(..)(..)") -- ./ldtk/ldtk.can:75
r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) -- ./ldtk/ldtk.can:76
return { -- ./ldtk/ldtk.can:77
r / 255, -- ./ldtk/ldtk.can:77
g / 255, -- ./ldtk/ldtk.can:77
b / 255 -- ./ldtk/ldtk.can:77
} -- ./ldtk/ldtk.can:77
end -- ./ldtk/ldtk.can:77
local white -- ./ldtk/ldtk.can:79
white = { -- ./ldtk/ldtk.can:79
1, -- ./ldtk/ldtk.can:79
1, -- ./ldtk/ldtk.can:79
1 -- ./ldtk/ldtk.can:79
} -- ./ldtk/ldtk.can:79
local makeTilesetRect -- ./ldtk/ldtk.can:82
makeTilesetRect = function(tilesetRect, project) -- ./ldtk/ldtk.can:82
local tileset = cache["tileset"](project["_tilesetData"][tilesetRect["tilesetUid"]]) -- ./ldtk/ldtk.can:83
local quad = tileset:_newQuad(tilesetRect["x"], tilesetRect["y"], tilesetRect["w"], tilesetRect["h"]) -- ./ldtk/ldtk.can:84
return { -- ./ldtk/ldtk.can:85
["tileset"] = tileset, -- ./ldtk/ldtk.can:86
["quad"] = quad -- ./ldtk/ldtk.can:87
} -- ./ldtk/ldtk.can:87
end -- ./ldtk/ldtk.can:87
local toLua -- ./ldtk/ldtk.can:92
toLua = function(type, val, parent_entity) -- ./ldtk/ldtk.can:92
if val == nil then -- ./ldtk/ldtk.can:93
return val -- ./ldtk/ldtk.can:93
end -- ./ldtk/ldtk.can:93
if type:match("^Array%<") then -- ./ldtk/ldtk.can:94
local itype = type:match("^Array%<(.*)%>$") -- ./ldtk/ldtk.can:95
for i, v in ipairs(val) do -- ./ldtk/ldtk.can:96
val[i] = toLua(itype, v, parent_entity) -- ./ldtk/ldtk.can:97
end -- ./ldtk/ldtk.can:97
elseif type == "Color" then -- ./ldtk/ldtk.can:99
return parseColor(val) -- ./ldtk/ldtk.can:100
elseif type == "Point" then -- ./ldtk/ldtk.can:101
assert(parent_entity, "AFAIK, it's not possible to have a Point field in something that's not an entity") -- ./ldtk/ldtk.can:102
return { -- ./ldtk/ldtk.can:103
["x"] = val["cx"] * parent_entity["layer"]["gridSize"], -- ./ldtk/ldtk.can:104
["y"] = val["cy"] * parent_entity["layer"]["gridSize"] -- ./ldtk/ldtk.can:105
} -- ./ldtk/ldtk.can:105
elseif type == "Tile" then -- ./ldtk/ldtk.can:107
assert(parent_entity, "AFAIK, it's not possible to have a Tile field in something that's not an entity") -- ./ldtk/ldtk.can:108
return makeTilesetRect(val, parent_entity["layer"]["level"]["project"]) -- ./ldtk/ldtk.can:109
elseif type == "EntityRef" then -- ./ldtk/ldtk.can:110
assert(parent_entity, "AFAIK, it's not possible to have an EntityRef field in something that's not an entity") -- ./ldtk/ldtk.can:111
local entityRef = setmetatable({ -- ./ldtk/ldtk.can:112
["level"] = parent_entity["layer"]["level"]["project"]["levels"][val["levelIid"]], -- ./ldtk/ldtk.can:113
["layerIid"] = val["layerIid"], -- ./ldtk/ldtk.can:114
["entityIid"] = val["entityIid"], -- ./ldtk/ldtk.can:115
["entity"] = nil -- ./ldtk/ldtk.can:116
}, { ["__index"] = function(self, k) -- ./ldtk/ldtk.can:118
if self["level"]["loaded"] then -- ./ldtk/ldtk.can:119
if k == "entity" then -- ./ldtk/ldtk.can:120
self["entity"] = self["level"]["layers"][self["layerIid"]]["entities"][self["entityIid"]] -- ./ldtk/ldtk.can:121
return self["entity"] -- ./ldtk/ldtk.can:122
end -- ./ldtk/ldtk.can:122
end -- ./ldtk/ldtk.can:122
return nil -- ./ldtk/ldtk.can:125
end }) -- ./ldtk/ldtk.can:125
return entityRef -- ./ldtk/ldtk.can:128
end -- ./ldtk/ldtk.can:128
return val -- ./ldtk/ldtk.can:130
end -- ./ldtk/ldtk.can:130
local getFields -- ./ldtk/ldtk.can:132
getFields = function(f, parent_entity) -- ./ldtk/ldtk.can:132
local t = {} -- ./ldtk/ldtk.can:133
for _, v in ipairs(f) do -- ./ldtk/ldtk.can:134
t[v["__identifier"]] = toLua(v["__type"], v["__value"], parent_entity) -- ./ldtk/ldtk.can:135
end -- ./ldtk/ldtk.can:135
return t -- ./ldtk/ldtk.can:137
end -- ./ldtk/ldtk.can:137
local tileset_mt -- ./ldtk/ldtk.can:140
local make_cache -- ./ldtk/ldtk.can:143
make_cache = function(new_fn) -- ./ldtk/ldtk.can:143
return setmetatable({}, { -- ./ldtk/ldtk.can:144
["__mode"] = "v", -- ./ldtk/ldtk.can:145
["__call"] = function(cache, id) -- ./ldtk/ldtk.can:146
if not cache[id] then -- ./ldtk/ldtk.can:147
cache[id] = new_fn(id) -- ./ldtk/ldtk.can:148
end -- ./ldtk/ldtk.can:148
return cache[id] -- ./ldtk/ldtk.can:150
end -- ./ldtk/ldtk.can:150
}) -- ./ldtk/ldtk.can:150
end -- ./ldtk/ldtk.can:150
cache = { -- ./ldtk/ldtk.can:154
["tileset"] = make_cache(function(tilesetDef) -- ./ldtk/ldtk.can:155
return tileset_mt["_init"](tilesetDef) -- ./ldtk/ldtk.can:156
end), -- ./ldtk/ldtk.can:156
["image"] = make_cache(function(path) -- ./ldtk/ldtk.can:158
if lg then -- ./ldtk/ldtk.can:159
return lg["newImage"](path) -- ./ldtk/ldtk.can:160
else -- ./ldtk/ldtk.can:160
return path -- ./ldtk/ldtk.can:162
end -- ./ldtk/ldtk.can:162
end) -- ./ldtk/ldtk.can:162
} -- ./ldtk/ldtk.can:162
tileset_mt = { -- ./ldtk/ldtk.can:170
["_newQuad"] = function(self, x, y, width, height) -- ./ldtk/ldtk.can:171
return newQuad(x, y, width, height, self["image"]) -- ./ldtk/ldtk.can:172
end, -- ./ldtk/ldtk.can:172
["_getTileQuad"] = function(self, tileid, x, y, size) -- ./ldtk/ldtk.can:174
if not self["_tileQuads"][tileid] then -- ./ldtk/ldtk.can:175
self["_tileQuads"][tileid] = self:_newQuad(x, y, size, size) -- ./ldtk/ldtk.can:176
end -- ./ldtk/ldtk.can:176
return self["_tileQuads"][tileid] -- ./ldtk/ldtk.can:178
end, -- ./ldtk/ldtk.can:178
["_init"] = function(tilesetDef) -- ./ldtk/ldtk.can:180
assert(not tilesetDef["embedAtlas"], "cannot load a tileset that use an internal LDtk atlas image, please use external tileset images") -- ./ldtk/ldtk.can:181
assert(tilesetDef["path"], "cannot load a tileset that has no image associated") -- ./ldtk/ldtk.can:182
local t = { -- ./ldtk/ldtk.can:183
["image"] = cache["image"](tilesetDef["path"]), -- ./ldtk/ldtk.can:186
["tags"] = tilesetDef["tags"], -- ./ldtk/ldtk.can:190
["_tileQuads"] = {} -- ./ldtk/ldtk.can:192
} -- ./ldtk/ldtk.can:192
return setmetatable(t, tileset_mt) -- ./ldtk/ldtk.can:194
end -- ./ldtk/ldtk.can:194
} -- ./ldtk/ldtk.can:194
tileset_mt["__index"] = tileset_mt -- ./ldtk/ldtk.can:197
local layer_mt -- ./ldtk/ldtk.can:204
layer_mt = { -- ./ldtk/ldtk.can:204
["draw"] = function(self, x, y) -- ./ldtk/ldtk.can:212
if x == nil then x = 0 end -- ./ldtk/ldtk.can:212
if y == nil then y = 0 end -- ./ldtk/ldtk.can:212
if self["visible"] then -- ./ldtk/ldtk.can:213
lg["push"]() -- ./ldtk/ldtk.can:214
lg["translate"](x + self["x"], y + self["y"]) -- ./ldtk/ldtk.can:215
if self["spritebatch"] then -- ./ldtk/ldtk.can:216
lg["setColor"](1, 1, 1, self["opacity"]) -- ./ldtk/ldtk.can:217
lg["draw"](self["spritebatch"]) -- ./ldtk/ldtk.can:218
elseif self["intTiles"] then -- ./ldtk/ldtk.can:219
for _, t in ipairs(self["intTiles"]) do -- ./ldtk/ldtk.can:220
lg["setColor"](t["color"]) -- ./ldtk/ldtk.can:221
lg["rectangle"]("fill", t["x"], t["y"], t["layer"]["gridSize"], t["layer"]["gridSize"]) -- ./ldtk/ldtk.can:222
end -- ./ldtk/ldtk.can:222
elseif self["entities"] then -- ./ldtk/ldtk.can:224
for _, e in ipairs(self["entities"]) do -- ./ldtk/ldtk.can:225
if e["draw"] then -- ./ldtk/ldtk.can:226
e:draw() -- ./ldtk/ldtk.can:226
end -- ./ldtk/ldtk.can:226
end -- ./ldtk/ldtk.can:226
end -- ./ldtk/ldtk.can:226
lg["pop"]() -- ./ldtk/ldtk.can:229
end -- ./ldtk/ldtk.can:229
end, -- ./ldtk/ldtk.can:229
["_unloadCallbacks"] = function(self, callbacks) -- ./ldtk/ldtk.can:233
local onRemoveTile = callbacks["onRemoveTile"] -- ./ldtk/ldtk.can:234
if self["tiles"] and onRemoveTile then -- ./ldtk/ldtk.can:235
for _, t in ipairs(self["tiles"]) do -- ./ldtk/ldtk.can:236
onRemoveTile(t) -- ./ldtk/ldtk.can:237
end -- ./ldtk/ldtk.can:237
end -- ./ldtk/ldtk.can:237
local onRemoveIntTile = callbacks["onRemoveIntTile"] -- ./ldtk/ldtk.can:240
if self["intTiles"] and onRemoveIntTile then -- ./ldtk/ldtk.can:241
for _, t in ipairs(self["intTiles"]) do -- ./ldtk/ldtk.can:242
onRemoveIntTile(t) -- ./ldtk/ldtk.can:243
end -- ./ldtk/ldtk.can:243
end -- ./ldtk/ldtk.can:243
local onRemoveEntity = callbacks["onRemoveEntity"] -- ./ldtk/ldtk.can:246
if self["entities"] and onRemoveEntity then -- ./ldtk/ldtk.can:247
for _, e in ipairs(self["entities"]) do -- ./ldtk/ldtk.can:248
onRemoveEntity(e) -- ./ldtk/ldtk.can:249
end -- ./ldtk/ldtk.can:249
end -- ./ldtk/ldtk.can:249
end, -- ./ldtk/ldtk.can:249
["_init"] = function(layer, level, order, callbacks) -- ./ldtk/ldtk.can:253
local layerDef = level["project"]["_layerDef"][layer["layerDefUid"]] -- ./ldtk/ldtk.can:254
local gridSize -- ./ldtk/ldtk.can:255
gridSize = layer["__gridSize"] -- ./ldtk/ldtk.can:255
local t -- ./ldtk/ldtk.can:256
t = { -- ./ldtk/ldtk.can:256
["level"] = level, -- ./ldtk/ldtk.can:259
["iid"] = layer["iid"], -- ./ldtk/ldtk.can:262
["identifier"] = layer["__identifier"], -- ./ldtk/ldtk.can:265
["type"] = layer["__type"], -- ./ldtk/ldtk.can:268
["visible"] = layer["visible"], -- ./ldtk/ldtk.can:271
["opacity"] = layer["opacity"], -- ./ldtk/ldtk.can:274
["order"] = order, -- ./ldtk/ldtk.can:277
["x"] = layer["__pxTotalOffsetX"], -- ./ldtk/ldtk.can:280
["y"] = layer["__pxTotalOffsetY"], -- ./ldtk/ldtk.can:283
["gridSize"] = gridSize, -- ./ldtk/ldtk.can:286
["gridWidth"] = layer["__cWid"], -- ./ldtk/ldtk.can:289
["gridHeight"] = layer["__cHei"], -- ./ldtk/ldtk.can:292
["parallaxFactorX"] = layerDef["parallaxFactorX"], -- ./ldtk/ldtk.can:295
["parallaxFactorY"] = layerDef["parallaxFactorY"], -- ./ldtk/ldtk.can:298
["parallaxScaling"] = layerDef["parallaxScaling"], -- ./ldtk/ldtk.can:301
["entities"] = nil, -- ./ldtk/ldtk.can:305
["tiles"] = nil, -- ./ldtk/ldtk.can:309
["tileset"] = nil, -- ./ldtk/ldtk.can:313
["spritebatch"] = nil, -- ./ldtk/ldtk.can:318
["intTiles"] = nil -- ./ldtk/ldtk.can:322
} -- ./ldtk/ldtk.can:322
if layer["__tilesetDefUid"] then -- ./ldtk/ldtk.can:325
t["tiles"] = {} -- ./ldtk/ldtk.can:326
local tilesetData = level["project"]["_tilesetData"][layer["__tilesetDefUid"]] -- ./ldtk/ldtk.can:327
t["tileset"] = cache["tileset"](tilesetData) -- ./ldtk/ldtk.can:328
local tiles = layer["__type"] == "Tiles" and layer["gridTiles"] or layer["autoLayerTiles"] -- ./ldtk/ldtk.can:329
local onAddTile = callbacks["onAddTile"] -- ./ldtk/ldtk.can:330
if lg then -- ./ldtk/ldtk.can:331
t["spritebatch"] = lg["newSpriteBatch"](t["tileset"]["image"]) -- ./ldtk/ldtk.can:331
end -- ./ldtk/ldtk.can:331
for _, tl in ipairs(tiles) do -- ./ldtk/ldtk.can:332
local quad -- ./ldtk/ldtk.can:333
quad = t["tileset"]:_getTileQuad(tl["t"], tl["src"][1], tl["src"][2], gridSize) -- ./ldtk/ldtk.can:333
local sx, sy = 1, 1 -- ./ldtk/ldtk.can:334
local x, y -- ./ldtk/ldtk.can:335
x, y = tl["px"][1], tl["px"][2] -- ./ldtk/ldtk.can:335
local tile -- ./ldtk/ldtk.can:343
tile = { -- ./ldtk/ldtk.can:343
["layer"] = t, -- ./ldtk/ldtk.can:346
["x"] = x, -- ./ldtk/ldtk.can:349
["y"] = y, -- ./ldtk/ldtk.can:352
["flipX"] = false, -- ./ldtk/ldtk.can:355
["flipY"] = false, -- ./ldtk/ldtk.can:358
["tags"] = tilesetData[tl["t"]]["enumTags"], -- ./ldtk/ldtk.can:361
["data"] = tilesetData[tl["t"]]["data"], -- ./ldtk/ldtk.can:364
["quad"] = quad -- ./ldtk/ldtk.can:368
} -- ./ldtk/ldtk.can:368
if tl["f"] == 1 or tl["f"] == 3 then -- ./ldtk/ldtk.can:370
sx = - 1 -- ./ldtk/ldtk.can:371
x = x + (gridSize) -- ./ldtk/ldtk.can:372
tile["flipX"] = true -- ./ldtk/ldtk.can:373
end -- ./ldtk/ldtk.can:373
if tl["f"] == 2 or tl["f"] == 3 then -- ./ldtk/ldtk.can:375
sy = - 1 -- ./ldtk/ldtk.can:376
y = y + (gridSize) -- ./ldtk/ldtk.can:377
tile["flipY"] = true -- ./ldtk/ldtk.can:378
end -- ./ldtk/ldtk.can:378
if t["spritebatch"] then -- ./ldtk/ldtk.can:380
t["spritebatch"]:add(quad, x, y, 0, sx, sy) -- ./ldtk/ldtk.can:380
end -- ./ldtk/ldtk.can:380
table["insert"](t["tiles"], tile) -- ./ldtk/ldtk.can:381
if onAddTile then -- ./ldtk/ldtk.can:382
onAddTile(tile) -- ./ldtk/ldtk.can:382
end -- ./ldtk/ldtk.can:382
end -- ./ldtk/ldtk.can:382
elseif layer["__type"] == "IntGrid" then -- ./ldtk/ldtk.can:385
t["intTiles"] = {} -- ./ldtk/ldtk.can:386
local onAddIntTile = callbacks["onAddIntTile"] -- ./ldtk/ldtk.can:387
local values = layerDef["intGridValues"] -- ./ldtk/ldtk.can:388
for i, tl in ipairs(layer["intGridCsv"]) do -- ./ldtk/ldtk.can:389
if tl > 0 then -- ./ldtk/ldtk.can:390
local y -- ./ldtk/ldtk.can:391
y = math["floor"]((i - 1) / t["gridWidth"]) * gridSize -- ./ldtk/ldtk.can:391
local x -- ./ldtk/ldtk.can:392
x = ((i - 1) % t["gridWidth"]) * gridSize -- ./ldtk/ldtk.can:392
local tile -- ./ldtk/ldtk.can:400
tile = { -- ./ldtk/ldtk.can:400
["layer"] = t, -- ./ldtk/ldtk.can:403
["x"] = x, -- ./ldtk/ldtk.can:406
["y"] = y, -- ./ldtk/ldtk.can:409
["identifier"] = values[tl]["identifier"], -- ./ldtk/ldtk.can:412
["value"] = tl, -- ./ldtk/ldtk.can:415
["color"] = values[tl]["color"] -- ./ldtk/ldtk.can:418
} -- ./ldtk/ldtk.can:418
table["insert"](t["intTiles"], tile) -- ./ldtk/ldtk.can:420
if onAddIntTile then -- ./ldtk/ldtk.can:421
onAddIntTile(tile) -- ./ldtk/ldtk.can:421
end -- ./ldtk/ldtk.can:421
end -- ./ldtk/ldtk.can:421
end -- ./ldtk/ldtk.can:421
end -- ./ldtk/ldtk.can:421
if layer["__type"] == "Entities" then -- ./ldtk/ldtk.can:426
t["entities"] = {} -- ./ldtk/ldtk.can:427
local onAddEntity = callbacks["onAddEntity"] -- ./ldtk/ldtk.can:428
for _, e in ipairs(layer["entityInstances"]) do -- ./ldtk/ldtk.can:429
local entityDef -- ./ldtk/ldtk.can:430
entityDef = level["project"]["_entityData"][e["defUid"]] -- ./ldtk/ldtk.can:430
local entity -- ./ldtk/ldtk.can:438
entity = { -- ./ldtk/ldtk.can:438
["layer"] = t, -- ./ldtk/ldtk.can:441
["iid"] = e["iid"], -- ./ldtk/ldtk.can:444
["identifier"] = e["__identifier"], -- ./ldtk/ldtk.can:447
["x"] = e["px"][1], -- ./ldtk/ldtk.can:450
["y"] = e["px"][2], -- ./ldtk/ldtk.can:453
["width"] = e["width"], -- ./ldtk/ldtk.can:456
["height"] = e["height"], -- ./ldtk/ldtk.can:459
["sx"] = e["width"] / entityDef["width"], -- ./ldtk/ldtk.can:462
["sy"] = e["height"] / entityDef["height"], -- ./ldtk/ldtk.can:465
["pivotX"] = e["__pivot"][1] * e["width"], -- ./ldtk/ldtk.can:468
["pivotY"] = e["__pivot"][2] * e["height"], -- ./ldtk/ldtk.can:471
["color"] = parseColor(e["__smartColor"]), -- ./ldtk/ldtk.can:474
["tile"] = nil, -- ./ldtk/ldtk.can:478
["tags"] = e["__tags"], -- ./ldtk/ldtk.can:481
["fields"] = nil, -- ./ldtk/ldtk.can:484
["draw"] = function(self) -- ./ldtk/ldtk.can:490
if self["tile"] then -- ./ldtk/ldtk.can:491
local _, _, w, h -- ./ldtk/ldtk.can:492
_, _, w, h = self["tile"]["quad"]:getViewport() -- ./ldtk/ldtk.can:492
lg["setColor"](white) -- ./ldtk/ldtk.can:493
lg["draw"](self["tile"]["tileset"]["image"], self["tile"]["quad"], self["x"] - self["pivotX"], self["y"] - self["pivotY"], 0, self["width"] / w, self["height"] / h) -- ./ldtk/ldtk.can:494
else -- ./ldtk/ldtk.can:494
lg["setColor"](self["color"]) -- ./ldtk/ldtk.can:496
lg["rectangle"]("line", self["x"] - self["pivotX"], self["y"] - self["pivotY"], self["width"], self["height"]) -- ./ldtk/ldtk.can:497
end -- ./ldtk/ldtk.can:497
end -- ./ldtk/ldtk.can:497
} -- ./ldtk/ldtk.can:497
if e["__tile"] then -- ./ldtk/ldtk.can:501
entity["tile"] = makeTilesetRect(e["__tile"], level["project"]) -- ./ldtk/ldtk.can:502
end -- ./ldtk/ldtk.can:502
for _, tag in ipairs(entity["tags"]) do -- ./ldtk/ldtk.can:504
entity["tags"][tag] = true -- ./ldtk/ldtk.can:505
end -- ./ldtk/ldtk.can:505
entity["fields"] = getFields(e["fieldInstances"], entity) -- ./ldtk/ldtk.can:507
t["entities"][entity["iid"]] = entity -- ./ldtk/ldtk.can:508
table["insert"](t["entities"], entity) -- ./ldtk/ldtk.can:509
if onAddEntity then -- ./ldtk/ldtk.can:510
onAddEntity(entity) -- ./ldtk/ldtk.can:510
end -- ./ldtk/ldtk.can:510
end -- ./ldtk/ldtk.can:510
end -- ./ldtk/ldtk.can:510
return setmetatable(t, layer_mt) -- ./ldtk/ldtk.can:513
end -- ./ldtk/ldtk.can:513
} -- ./ldtk/ldtk.can:513
layer_mt["__index"] = layer_mt -- ./ldtk/ldtk.can:516
local level_mt -- ./ldtk/ldtk.can:525
level_mt = { -- ./ldtk/ldtk.can:525
["draw"] = function(self, x, y) -- ./ldtk/ldtk.can:536
if x == nil then x = 0 end -- ./ldtk/ldtk.can:536
if y == nil then y = 0 end -- ./ldtk/ldtk.can:536
assert(self["loaded"] == true, "level not loaded") -- ./ldtk/ldtk.can:537
lg["push"]() -- ./ldtk/ldtk.can:538
lg["translate"](x + self["x"], y + self["y"]) -- ./ldtk/ldtk.can:539
self:drawBackground() -- ./ldtk/ldtk.can:540
for _, l in ipairs(self["layers"]) do -- ./ldtk/ldtk.can:542
l:draw() -- ./ldtk/ldtk.can:543
end -- ./ldtk/ldtk.can:543
lg["pop"]() -- ./ldtk/ldtk.can:545
end, -- ./ldtk/ldtk.can:545
["drawBackground"] = function(self, x, y) -- ./ldtk/ldtk.can:556
if x == nil then x = 0 end -- ./ldtk/ldtk.can:556
if y == nil then y = 0 end -- ./ldtk/ldtk.can:556
assert(self["loaded"] == true, "level not loaded") -- ./ldtk/ldtk.can:557
lg["setColor"](self["background"]["color"]) -- ./ldtk/ldtk.can:559
lg["rectangle"]("fill", x, y, self["width"], self["height"]) -- ./ldtk/ldtk.can:560
lg["setColor"](white) -- ./ldtk/ldtk.can:562
local bgImage -- ./ldtk/ldtk.can:563
bgImage = self["background"]["image"] -- ./ldtk/ldtk.can:563
if bgImage then -- ./ldtk/ldtk.can:564
lg["draw"](bgImage["image"], bgImage["quad"], x + bgImage["x"], y + bgImage["y"], 0, bgImage["sx"], bgImage["sy"]) -- ./ldtk/ldtk.can:565
end -- ./ldtk/ldtk.can:565
end, -- ./ldtk/ldtk.can:565
["load"] = function(self, callbacks) -- ./ldtk/ldtk.can:583
if callbacks == nil then callbacks = {} end -- ./ldtk/ldtk.can:583
assert(self["loaded"] == false, "level already loaded") -- ./ldtk/ldtk.can:584
if self["_json"]["bgRelPath"] then -- ./ldtk/ldtk.can:585
local pos -- ./ldtk/ldtk.can:586
pos = self["_json"]["__bgPos"] -- ./ldtk/ldtk.can:586
local cropRect -- ./ldtk/ldtk.can:587
cropRect = pos["cropRect"] -- ./ldtk/ldtk.can:587
local image -- ./ldtk/ldtk.can:588
image = cache["image"](self["project"]["_directory"] .. self["_json"]["bgRelPath"]) -- ./ldtk/ldtk.can:588
self["background"]["image"] = { -- ./ldtk/ldtk.can:589
["image"] = image, -- ./ldtk/ldtk.can:590
["quad"] = newQuad(cropRect[1], cropRect[2], cropRect[3], cropRect[4], image), -- ./ldtk/ldtk.can:591
["x"] = pos["topLeftPx"][1], -- ./ldtk/ldtk.can:592
["y"] = pos["topLeftPx"][2], -- ./ldtk/ldtk.can:593
["sx"] = pos["scale"][1], -- ./ldtk/ldtk.can:594
["sy"] = pos["scale"][1] -- ./ldtk/ldtk.can:595
} -- ./ldtk/ldtk.can:595
end -- ./ldtk/ldtk.can:595
local layerInstances -- ./ldtk/ldtk.can:598
if self["_json"]["externalRelPath"] then -- ./ldtk/ldtk.can:599
layerInstances = readJson(self["project"]["_directory"] .. self["_json"]["externalRelPath"])["layerInstances"] -- ./ldtk/ldtk.can:600
else -- ./ldtk/ldtk.can:600
layerInstances = self["_json"]["layerInstances"] -- ./ldtk/ldtk.can:602
end -- ./ldtk/ldtk.can:602
self["layers"] = {} -- ./ldtk/ldtk.can:604
local onAddLayer -- ./ldtk/ldtk.can:605
onAddLayer = callbacks["onAddLayer"] -- ./ldtk/ldtk.can:605
for i = # layerInstances, 1, - 1 do -- ./ldtk/ldtk.can:606
local layer = layer_mt["_init"](layerInstances[i], self, i, callbacks) -- ./ldtk/ldtk.can:607
self["layers"][layer["iid"]] = layer -- ./ldtk/ldtk.can:608
table["insert"](self["layers"], layer) -- ./ldtk/ldtk.can:609
if onAddLayer then -- ./ldtk/ldtk.can:610
onAddLayer(layer) -- ./ldtk/ldtk.can:610
end -- ./ldtk/ldtk.can:610
end -- ./ldtk/ldtk.can:610
self["loaded"] = true -- ./ldtk/ldtk.can:612
end, -- ./ldtk/ldtk.can:612
["unload"] = function(self, callbacks) -- ./ldtk/ldtk.can:625
if callbacks == nil then callbacks = {} end -- ./ldtk/ldtk.can:625
assert(self["loaded"] == true, "level not loaded") -- ./ldtk/ldtk.can:626
local onRemoveLayer -- ./ldtk/ldtk.can:627
onRemoveLayer = callbacks["onRemoveLayer"] -- ./ldtk/ldtk.can:627
for _, l in ipairs(self["layers"]) do -- ./ldtk/ldtk.can:628
l:_unloadCallbacks(callbacks) -- ./ldtk/ldtk.can:629
if onRemoveLayer then -- ./ldtk/ldtk.can:630
onRemoveLayer(l) -- ./ldtk/ldtk.can:630
end -- ./ldtk/ldtk.can:630
end -- ./ldtk/ldtk.can:630
self["loaded"] = false -- ./ldtk/ldtk.can:632
self["background"]["image"] = nil -- ./ldtk/ldtk.can:633
self["layers"] = nil -- ./ldtk/ldtk.can:634
end, -- ./ldtk/ldtk.can:634
["_init"] = function(level, project) -- ./ldtk/ldtk.can:637
local t -- ./ldtk/ldtk.can:638
t = { -- ./ldtk/ldtk.can:638
["project"] = project, -- ./ldtk/ldtk.can:641
["loaded"] = false, -- ./ldtk/ldtk.can:644
["iid"] = level["iid"], -- ./ldtk/ldtk.can:647
["identifier"] = level["identifier"], -- ./ldtk/ldtk.can:650
["depth"] = level["worldDepth"], -- ./ldtk/ldtk.can:653
["x"] = level["worldX"], -- ./ldtk/ldtk.can:657
["y"] = level["worldY"], -- ./ldtk/ldtk.can:661
["width"] = level["pxWid"], -- ./ldtk/ldtk.can:664
["height"] = level["pxHei"], -- ./ldtk/ldtk.can:667
["fields"] = getFields(level["fieldInstances"]), -- ./ldtk/ldtk.can:670
["layers"] = nil, -- ./ldtk/ldtk.can:674
["background"] = { -- ./ldtk/ldtk.can:682
["color"] = parseColor(level["__bgColor"]), -- ./ldtk/ldtk.can:683
["image"] = nil -- ./ldtk/ldtk.can:684
}, -- ./ldtk/ldtk.can:684
["_json"] = level -- ./ldtk/ldtk.can:688
} -- ./ldtk/ldtk.can:688
return setmetatable(t, level_mt) -- ./ldtk/ldtk.can:690
end -- ./ldtk/ldtk.can:690
} -- ./ldtk/ldtk.can:690
level_mt["__index"] = level_mt -- ./ldtk/ldtk.can:693
local project_mt -- ./ldtk/ldtk.can:700
project_mt = { ["_init"] = function(project, directory) -- ./ldtk/ldtk.can:701
assert(project["jsonVersion"]:match("^1%.1%."), ("the map was made with LDtk version %s but the importer is made for 1.1.3"):format(project["jsonVersion"])) -- ./ldtk/ldtk.can:702
local t -- ./ldtk/ldtk.can:703
t = { -- ./ldtk/ldtk.can:703
["levels"] = nil, -- ./ldtk/ldtk.can:707
["_directory"] = directory, -- ./ldtk/ldtk.can:710
["_layerDef"] = nil, -- ./ldtk/ldtk.can:711
["_tilesetData"] = nil, -- ./ldtk/ldtk.can:712
["_entityData"] = nil -- ./ldtk/ldtk.can:713
} -- ./ldtk/ldtk.can:713
t["levels"] = (function() -- ./ldtk/ldtk.can:715
local self = {} -- ./ldtk/ldtk.can:715
for _, lvl in ipairs(project["levels"]) do -- ./ldtk/ldtk.can:716
local level = level_mt["_init"](lvl, t) -- ./ldtk/ldtk.can:717
self[lvl["iid"]] = level -- ./ldtk/ldtk.can:718
self[#self+1] = level -- ./ldtk/ldtk.can:719
end -- ./ldtk/ldtk.can:719
return self -- ./ldtk/ldtk.can:719
end)() -- ./ldtk/ldtk.can:719
t["_tilesetData"] = (function() -- ./ldtk/ldtk.can:722
local self = {} -- ./ldtk/ldtk.can:722
for _, ts in ipairs(project["defs"]["tilesets"]) do -- ./ldtk/ldtk.can:723
self[ts["uid"]] = { ["tags"] = ts["tags"] } -- ./ldtk/ldtk.can:725
if ts["relPath"] then -- ./ldtk/ldtk.can:727
self[ts["uid"]]["path"] = directory .. ts["relPath"] -- ./ldtk/ldtk.can:728
elseif ts["embedAtlas"] then -- ./ldtk/ldtk.can:729
self[ts["uid"]]["embedAtlas"] = true -- ./ldtk/ldtk.can:730
end -- ./ldtk/ldtk.can:730
for _, tag in ipairs(ts["tags"]) do -- ./ldtk/ldtk.can:732
self[ts["uid"]]["tags"][tag] = true -- ./ldtk/ldtk.can:733
end -- ./ldtk/ldtk.can:733
local tilesetData = self[ts["uid"]] -- ./ldtk/ldtk.can:735
for gridx = 0, ts["__cWid"] - 1 do -- ./ldtk/ldtk.can:736
for gridy = 0, ts["__cHei"] - 1 do -- ./ldtk/ldtk.can:737
tilesetData[gridx + gridy * ts["__cWid"]] = { -- ./ldtk/ldtk.can:738
["enumTags"] = {}, -- ./ldtk/ldtk.can:739
["data"] = nil -- ./ldtk/ldtk.can:740
} -- ./ldtk/ldtk.can:740
end -- ./ldtk/ldtk.can:740
end -- ./ldtk/ldtk.can:740
for _, custom in ipairs(ts["customData"]) do -- ./ldtk/ldtk.can:744
tilesetData[custom["tileId"]]["data"] = custom["data"] -- ./ldtk/ldtk.can:745
end -- ./ldtk/ldtk.can:745
for _, tag in ipairs(ts["enumTags"]) do -- ./ldtk/ldtk.can:747
local value = tag["enumValueId"] -- ./ldtk/ldtk.can:748
for _, tileId in ipairs(tag["tileIds"]) do -- ./ldtk/ldtk.can:749
table["insert"](tilesetData[tileId]["enumTags"], value) -- ./ldtk/ldtk.can:750
tilesetData[tileId]["enumTags"][value] = true -- ./ldtk/ldtk.can:751
end -- ./ldtk/ldtk.can:751
end -- ./ldtk/ldtk.can:751
end -- ./ldtk/ldtk.can:751
return self -- ./ldtk/ldtk.can:751
end)() -- ./ldtk/ldtk.can:751
t["_layerDef"] = (function() -- ./ldtk/ldtk.can:756
local self = {} -- ./ldtk/ldtk.can:756
for _, lay in ipairs(project["defs"]["layers"]) do -- ./ldtk/ldtk.can:757
self[lay["uid"]] = { -- ./ldtk/ldtk.can:758
["intGridValues"] = nil, -- ./ldtk/ldtk.can:759
["parallaxFactorX"] = lay["parallaxFactorX"], -- ./ldtk/ldtk.can:760
["parallaxFactorY"] = lay["parallaxFactorY"], -- ./ldtk/ldtk.can:761
["parallaxScaling"] = lay["parallaxScaling"] -- ./ldtk/ldtk.can:762
} -- ./ldtk/ldtk.can:762
local layerDef = self[lay["uid"]] -- ./ldtk/ldtk.can:764
if lay["__type"] == "IntGrid" then -- ./ldtk/ldtk.can:765
layerDef["intGridValues"] = (function() -- ./ldtk/ldtk.can:766
local self = {} -- ./ldtk/ldtk.can:766
for _, v in ipairs(lay["intGridValues"]) do -- ./ldtk/ldtk.can:767
self[v["value"]] = { -- ./ldtk/ldtk.can:768
["color"] = parseColor(v["color"]), -- ./ldtk/ldtk.can:769
["identifier"] = v["identifier"] -- ./ldtk/ldtk.can:770
} -- ./ldtk/ldtk.can:770
end -- ./ldtk/ldtk.can:770
return self -- ./ldtk/ldtk.can:770
end)() -- ./ldtk/ldtk.can:770
end -- ./ldtk/ldtk.can:770
end -- ./ldtk/ldtk.can:770
return self -- ./ldtk/ldtk.can:770
end)() -- ./ldtk/ldtk.can:770
t["_entityData"] = (function() -- ./ldtk/ldtk.can:777
local self = {} -- ./ldtk/ldtk.can:777
for _, ent in ipairs(project["defs"]["entities"]) do -- ./ldtk/ldtk.can:778
self[ent["uid"]] = { -- ./ldtk/ldtk.can:779
["width"] = ent["width"], -- ./ldtk/ldtk.can:780
["height"] = ent["height"], -- ./ldtk/ldtk.can:781
["nineSliceBorders"] = # ent["nineSliceBorders"] > 0 and ent["nineSliceBorders"] or nil -- ./ldtk/ldtk.can:782
} -- ./ldtk/ldtk.can:782
end -- ./ldtk/ldtk.can:782
return self -- ./ldtk/ldtk.can:782
end)() -- ./ldtk/ldtk.can:782
return setmetatable(t, project_mt) -- ./ldtk/ldtk.can:786
end } -- ./ldtk/ldtk.can:786
project_mt["__index"] = project_mt -- ./ldtk/ldtk.can:789
return function(file) -- ./ldtk/ldtk.can:822
return project_mt["_init"](readJson(file), file:match("^(.-)[^%/%\\]+$")) -- ./ldtk/ldtk.can:823
end -- ./ldtk/ldtk.can:823
