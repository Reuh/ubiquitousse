local loaded, scene -- ./ecs/ecs.can:54
if ... then -- ./ecs/ecs.can:55
loaded, scene = pcall(require, (...):match("^(.-)ecs") .. "scene") -- ./ecs/ecs.can:55
end -- ./ecs/ecs.can:55
if not loaded then -- ./ecs/ecs.can:56
scene = nil -- ./ecs/ecs.can:56
end -- ./ecs/ecs.can:56
local ecs -- ./ecs/ecs.can:58
local recDestroySystems -- ./ecs/ecs.can:104
recDestroySystems = function(system) -- ./ecs/ecs.can:104
for i = # system["systems"], 1, - 1 do -- ./ecs/ecs.can:105
local s -- ./ecs/ecs.can:106
s = system["systems"][i] -- ./ecs/ecs.can:106
recDestroySystems(s) -- ./ecs/ecs.can:107
s:onDestroy() -- ./ecs/ecs.can:108
system["systems"][i] = nil -- ./ecs/ecs.can:109
if s["name"] then -- ./ecs/ecs.can:110
system["world"]["s"][s["name"]] = nil -- ./ecs/ecs.can:111
end -- ./ecs/ecs.can:111
end -- ./ecs/ecs.can:111
end -- ./ecs/ecs.can:111
local recCallOnRemoveFromWorld -- ./ecs/ecs.can:116
recCallOnRemoveFromWorld = function(world, systems) -- ./ecs/ecs.can:116
for _, s in ipairs(systems) do -- ./ecs/ecs.can:117
s:clear() -- ./ecs/ecs.can:118
recCallOnRemoveFromWorld(world, s["systems"]) -- ./ecs/ecs.can:119
s:onRemoveFromWorld(world) -- ./ecs/ecs.can:120
end -- ./ecs/ecs.can:120
end -- ./ecs/ecs.can:120
local copy -- ./ecs/ecs.can:126
copy = function(a, b, cache) -- ./ecs/ecs.can:126
if cache == nil then cache = {} end -- ./ecs/ecs.can:126
for k, v in pairs(a) do -- ./ecs/ecs.can:127
if type(v) == "table" then -- ./ecs/ecs.can:128
if b[k] == nil then -- ./ecs/ecs.can:129
if cache[v] then -- ./ecs/ecs.can:130
b[k] = cache[v] -- ./ecs/ecs.can:131
else -- ./ecs/ecs.can:131
cache[v] = {} -- ./ecs/ecs.can:133
b[k] = cache[v] -- ./ecs/ecs.can:134
copy(v, b[k], cache) -- ./ecs/ecs.can:135
setmetatable(b[k], getmetatable(v)) -- ./ecs/ecs.can:136
end -- ./ecs/ecs.can:136
elseif type(b[k]) == "table" then -- ./ecs/ecs.can:138
copy(v, b[k], cache) -- ./ecs/ecs.can:139
end -- ./ecs/ecs.can:139
elseif b[k] == nil then -- ./ecs/ecs.can:141
b[k] = v -- ./ecs/ecs.can:142
end -- ./ecs/ecs.can:142
end -- ./ecs/ecs.can:142
end -- ./ecs/ecs.can:142
local head -- ./ecs/ecs.can:151
head = {} -- ./ecs/ecs.can:151
local skipNew -- ./ecs/ecs.can:154
skipNew = function() -- ./ecs/ecs.can:154
local s -- ./ecs/ecs.can:155
s = { -- ./ecs/ecs.can:155
["first"] = { -- ./ecs/ecs.can:158
head, -- ./ecs/ecs.can:158
nil -- ./ecs/ecs.can:158
}, -- ./ecs/ecs.can:158
["firstBase"] = nil, -- ./ecs/ecs.can:160
["previous"] = { {} }, -- ./ecs/ecs.can:164
["nLayers"] = 1, -- ./ecs/ecs.can:166
["n"] = 0 -- ./ecs/ecs.can:168
} -- ./ecs/ecs.can:168
s["firstBase"] = s["first"] -- ./ecs/ecs.can:170
return s -- ./ecs/ecs.can:171
end -- ./ecs/ecs.can:171
local nextEntity -- ./ecs/ecs.can:175
nextEntity = function(s) -- ./ecs/ecs.can:175
if s[1] then -- ./ecs/ecs.can:176
local var -- ./ecs/ecs.can:177
var = s[1][1] -- ./ecs/ecs.can:177
s[1] = s[1][2] -- ./ecs/ecs.can:178
return var -- ./ecs/ecs.can:179
else -- ./ecs/ecs.can:179
return nil -- ./ecs/ecs.can:181
end -- ./ecs/ecs.can:181
end -- ./ecs/ecs.can:181
local skipIter -- ./ecs/ecs.can:186
skipIter = function(self) -- ./ecs/ecs.can:186
return nextEntity, { self["firstBase"][2] } -- ./ecs/ecs.can:187
end -- ./ecs/ecs.can:187
local skipAddLayers -- ./ecs/ecs.can:193
skipAddLayers = function(self) -- ./ecs/ecs.can:193
while self["n"] > 2 ^ self["nLayers"] do -- ./ecs/ecs.can:194
self["first"] = { -- ./ecs/ecs.can:195
head, -- ./ecs/ecs.can:195
nil, -- ./ecs/ecs.can:195
self["first"] -- ./ecs/ecs.can:195
} -- ./ecs/ecs.can:195
table["insert"](self["previous"], {}) -- ./ecs/ecs.can:196
self["nLayers"] = self["nLayers"] + (1) -- ./ecs/ecs.can:197
end -- ./ecs/ecs.can:197
end -- ./ecs/ecs.can:197
local coinFlip -- ./ecs/ecs.can:202
coinFlip = function() -- ./ecs/ecs.can:202
return math["random"](0, 1) == 1 -- ./ecs/ecs.can:203
end -- ./ecs/ecs.can:203
local skipInsert -- ./ecs/ecs.can:208
skipInsert = function(self, system, e) -- ./ecs/ecs.can:208
local prevLayer -- ./ecs/ecs.can:210
prevLayer = {} -- ./ecs/ecs.can:210
local prev -- ./ecs/ecs.can:211
prev = self["first"] -- ./ecs/ecs.can:211
for i = self["nLayers"], 1, - 1 do -- ./ecs/ecs.can:212
while true do -- ./ecs/ecs.can:213
if prev[2] == nil or system:compare(e, prev[2][1]) then -- ./ecs/ecs.can:215
prevLayer[i] = prev -- ./ecs/ecs.can:216
if prev[3] then -- ./ecs/ecs.can:218
prev = prev[3] -- ./ecs/ecs.can:219
break -- ./ecs/ecs.can:220
end -- ./ecs/ecs.can:220
break -- ./ecs/ecs.can:222
else -- ./ecs/ecs.can:222
prev = prev[2] -- ./ecs/ecs.can:225
end -- ./ecs/ecs.can:225
end -- ./ecs/ecs.can:225
end -- ./ecs/ecs.can:225
local inLowerLayer -- ./ecs/ecs.can:230
for i = 1, self["nLayers"] do -- ./ecs/ecs.can:231
prev = prevLayer[i] -- ./ecs/ecs.can:232
if i == 1 or coinFlip() then -- ./ecs/ecs.can:233
local nxt -- ./ecs/ecs.can:234
nxt = prev[2] -- ./ecs/ecs.can:234
prev[2] = { -- ./ecs/ecs.can:235
e, -- ./ecs/ecs.can:235
nxt, -- ./ecs/ecs.can:235
inLowerLayer -- ./ecs/ecs.can:235
} -- ./ecs/ecs.can:235
self["previous"][i][e] = prev -- ./ecs/ecs.can:236
if nxt then -- ./ecs/ecs.can:237
self["previous"][i][nxt[1]] = prev[2] -- ./ecs/ecs.can:238
end -- ./ecs/ecs.can:238
inLowerLayer = prev[2] -- ./ecs/ecs.can:240
else -- ./ecs/ecs.can:240
break -- ./ecs/ecs.can:242
end -- ./ecs/ecs.can:242
end -- ./ecs/ecs.can:242
self["n"] = self["n"] + (1) -- ./ecs/ecs.can:245
end -- ./ecs/ecs.can:245
local skipDelete -- ./ecs/ecs.can:251
skipDelete = function(self, e) -- ./ecs/ecs.can:251
for i = 1, self["nLayers"] do -- ./ecs/ecs.can:253
local previous -- ./ecs/ecs.can:254
previous = self["previous"][i] -- ./ecs/ecs.can:254
if previous[e] then -- ./ecs/ecs.can:255
local prev -- ./ecs/ecs.can:256
prev = previous[e] -- ./ecs/ecs.can:256
prev[2] = prev[2][2] -- ./ecs/ecs.can:257
previous[e] = nil -- ./ecs/ecs.can:258
if prev[2] then -- ./ecs/ecs.can:259
previous[prev[2][1]] = prev -- ./ecs/ecs.can:260
end -- ./ecs/ecs.can:260
else -- ./ecs/ecs.can:260
break -- ./ecs/ecs.can:263
end -- ./ecs/ecs.can:263
end -- ./ecs/ecs.can:263
self["n"] = self["n"] - (1) -- ./ecs/ecs.can:266
end -- ./ecs/ecs.can:266
local skipReorder -- ./ecs/ecs.can:272
skipReorder = function(self, system, e) -- ./ecs/ecs.can:272
skipDelete(self, e) -- ./ecs/ecs.can:273
skipInsert(self, system, e) -- ./ecs/ecs.can:274
end -- ./ecs/ecs.can:274
local skipIndex -- ./ecs/ecs.can:279
skipIndex = function(self, i) -- ./ecs/ecs.can:279
local n = 1 -- ./ecs/ecs.can:280
for e in skipIter(self) do -- ./ecs/ecs.can:281
if n == i then -- ./ecs/ecs.can:282
return e -- ./ecs/ecs.can:283
end -- ./ecs/ecs.can:283
n = n + (1) -- ./ecs/ecs.can:285
end -- ./ecs/ecs.can:285
return nil -- ./ecs/ecs.can:287
end -- ./ecs/ecs.can:287
local system_mt -- ./ecs/ecs.can:351
system_mt = { -- ./ecs/ecs.can:351
["name"] = nil, -- ./ecs/ecs.can:365
["systems"] = nil, -- ./ecs/ecs.can:373
["interval"] = false, -- ./ecs/ecs.can:379
["active"] = true, -- ./ecs/ecs.can:383
["visible"] = true, -- ./ecs/ecs.can:387
["component"] = nil, -- ./ecs/ecs.can:394
["default"] = nil, -- ./ecs/ecs.can:404
["filter"] = function(self, e) -- ./ecs/ecs.can:425
return false -- ./ecs/ecs.can:425
end, -- ./ecs/ecs.can:425
["compare"] = function(self, e1, e2) -- ./ecs/ecs.can:437
return true -- ./ecs/ecs.can:437
end, -- ./ecs/ecs.can:437
["onAdd"] = function(self, e, c) -- ./ecs/ecs.can:443
 -- ./ecs/ecs.can:443
end, -- ./ecs/ecs.can:443
["onRemove"] = function(self, e, c) -- ./ecs/ecs.can:448
 -- ./ecs/ecs.can:448
end, -- ./ecs/ecs.can:448
["onInstance"] = function(self) -- ./ecs/ecs.can:451
 -- ./ecs/ecs.can:451
end, -- ./ecs/ecs.can:451
["onAddToWorld"] = function(self, world) -- ./ecs/ecs.can:455
 -- ./ecs/ecs.can:455
end, -- ./ecs/ecs.can:455
["onRemoveFromWorld"] = function(self, world) -- ./ecs/ecs.can:459
 -- ./ecs/ecs.can:459
end, -- ./ecs/ecs.can:459
["onDestroy"] = function(self) -- ./ecs/ecs.can:462
 -- ./ecs/ecs.can:462
end, -- ./ecs/ecs.can:462
["onUpdate"] = function(self, dt) -- ./ecs/ecs.can:467
 -- ./ecs/ecs.can:467
end, -- ./ecs/ecs.can:467
["onDraw"] = function(self) -- ./ecs/ecs.can:471
 -- ./ecs/ecs.can:471
end, -- ./ecs/ecs.can:471
["process"] = function(self, e, c, dt) -- ./ecs/ecs.can:478
 -- ./ecs/ecs.can:478
end, -- ./ecs/ecs.can:478
["render"] = function(self, e, c) -- ./ecs/ecs.can:484
 -- ./ecs/ecs.can:484
end, -- ./ecs/ecs.can:484
["onUpdateEnd"] = function(self, dt) -- ./ecs/ecs.can:489
 -- ./ecs/ecs.can:489
end, -- ./ecs/ecs.can:489
["onDrawEnd"] = function(self) -- ./ecs/ecs.can:493
 -- ./ecs/ecs.can:493
end, -- ./ecs/ecs.can:493
["world"] = nil, -- ./ecs/ecs.can:503
["w"] = nil, -- ./ecs/ecs.can:507
["entityCount"] = 0, -- ./ecs/ecs.can:511
["s"] = nil, -- ./ecs/ecs.can:515
["_has"] = nil, -- ./ecs/ecs.can:523
["_waited"] = 0, -- ./ecs/ecs.can:527
["add"] = function(self, e, ...) -- ./ecs/ecs.can:548
if e ~= nil and not self["_has"][e] and self:filter(e) then -- ./ecs/ecs.can:549
if self["component"] and self["default"] then -- ./ecs/ecs.can:551
copy({ [self["component"]] = self["default"] }, e) -- ./ecs/ecs.can:552
end -- ./ecs/ecs.can:552
if self["compare"] ~= system_mt["compare"] then -- ./ecs/ecs.can:555
skipAddLayers(self["_skiplist"]) -- ./ecs/ecs.can:556
end -- ./ecs/ecs.can:556
skipInsert(self["_skiplist"], self, e) -- ./ecs/ecs.can:559
self["entityCount"] = self["entityCount"] + (1) -- ./ecs/ecs.can:561
self:onAdd(e, e[self["component"]]) -- ./ecs/ecs.can:562
if self["_has"][e] then -- ./ecs/ecs.can:564
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:565
s:add(e) -- ./ecs/ecs.can:566
end -- ./ecs/ecs.can:566
end -- ./ecs/ecs.can:566
end -- ./ecs/ecs.can:566
if ... then -- ./ecs/ecs.can:570
return e, self:add(...) -- ./ecs/ecs.can:571
else -- ./ecs/ecs.can:571
return e -- ./ecs/ecs.can:573
end -- ./ecs/ecs.can:573
end, -- ./ecs/ecs.can:573
["remove"] = function(self, e, ...) -- ./ecs/ecs.can:588
if e ~= nil then -- ./ecs/ecs.can:589
if self["_has"][e] then -- ./ecs/ecs.can:590
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:592
s:remove(e) -- ./ecs/ecs.can:593
end -- ./ecs/ecs.can:593
end -- ./ecs/ecs.can:593
if self["_has"][e] then -- ./ecs/ecs.can:596
skipDelete(self["_skiplist"], e) -- ./ecs/ecs.can:597
self["entityCount"] = self["entityCount"] - (1) -- ./ecs/ecs.can:599
self:onRemove(e, e[self["component"]]) -- ./ecs/ecs.can:600
end -- ./ecs/ecs.can:600
end -- ./ecs/ecs.can:600
if ... then -- ./ecs/ecs.can:603
return e, self:remove(...) -- ./ecs/ecs.can:604
else -- ./ecs/ecs.can:604
return e -- ./ecs/ecs.can:606
end -- ./ecs/ecs.can:606
end, -- ./ecs/ecs.can:606
["refresh"] = function(self, e, ...) -- ./ecs/ecs.can:618
if e ~= nil then -- ./ecs/ecs.can:619
if not self["_has"][e] then -- ./ecs/ecs.can:620
self:add(e) -- ./ecs/ecs.can:621
else -- ./ecs/ecs.can:621
if not self:filter(e) then -- ./ecs/ecs.can:623
self:remove(e) -- ./ecs/ecs.can:624
else -- ./ecs/ecs.can:624
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:626
s:refresh(e) -- ./ecs/ecs.can:627
end -- ./ecs/ecs.can:627
end -- ./ecs/ecs.can:627
end -- ./ecs/ecs.can:627
end -- ./ecs/ecs.can:627
if ... then -- ./ecs/ecs.can:632
return e, self:refresh(...) -- ./ecs/ecs.can:633
else -- ./ecs/ecs.can:633
return e -- ./ecs/ecs.can:635
end -- ./ecs/ecs.can:635
end, -- ./ecs/ecs.can:635
["reorder"] = function(self, e, ...) -- ./ecs/ecs.can:647
if e ~= nil and self["_has"][e] then -- ./ecs/ecs.can:648
skipReorder(self["_skiplist"], self, e) -- ./ecs/ecs.can:649
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:651
s:reorder(e) -- ./ecs/ecs.can:652
end -- ./ecs/ecs.can:652
end -- ./ecs/ecs.can:652
if ... then -- ./ecs/ecs.can:655
return e, self:reorder(...) -- ./ecs/ecs.can:656
else -- ./ecs/ecs.can:656
return e -- ./ecs/ecs.can:658
end -- ./ecs/ecs.can:658
end, -- ./ecs/ecs.can:658
["has"] = function(self, e, ...) -- ./ecs/ecs.can:667
local has -- ./ecs/ecs.can:668
has = e == nil or not not self["_has"][e] -- ./ecs/ecs.can:668
if ... then -- ./ecs/ecs.can:669
return has and self:has(...) -- ./ecs/ecs.can:670
else -- ./ecs/ecs.can:670
return has -- ./ecs/ecs.can:672
end -- ./ecs/ecs.can:672
end, -- ./ecs/ecs.can:672
["iter"] = function(self) -- ./ecs/ecs.can:679
return skipIter(self["_skiplist"]) -- ./ecs/ecs.can:680
end, -- ./ecs/ecs.can:680
["get"] = function(self, i) -- ./ecs/ecs.can:687
return skipIndex(self["_skiplist"], i) -- ./ecs/ecs.can:688
end, -- ./ecs/ecs.can:688
["clear"] = function(self) -- ./ecs/ecs.can:693
for e in skipIter(self["_skiplist"]) do -- ./ecs/ecs.can:694
self:remove(e) -- ./ecs/ecs.can:695
end -- ./ecs/ecs.can:695
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:697
s:clear() -- ./ecs/ecs.can:698
end -- ./ecs/ecs.can:698
end, -- ./ecs/ecs.can:698
["update"] = function(self, dt) -- ./ecs/ecs.can:707
if self["active"] then -- ./ecs/ecs.can:708
if self["interval"] then -- ./ecs/ecs.can:709
self["_waited"] = self["_waited"] + (dt) -- ./ecs/ecs.can:710
if self["_waited"] < self["interval"] then -- ./ecs/ecs.can:711
return  -- ./ecs/ecs.can:712
end -- ./ecs/ecs.can:712
end -- ./ecs/ecs.can:712
self:onUpdate(dt) -- ./ecs/ecs.can:715
if self["process"] ~= system_mt["process"] then -- ./ecs/ecs.can:716
for e in skipIter(self["_skiplist"]) do -- ./ecs/ecs.can:717
self:process(e, e[self["component"]], dt) -- ./ecs/ecs.can:718
end -- ./ecs/ecs.can:718
end -- ./ecs/ecs.can:718
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:721
s:update(dt) -- ./ecs/ecs.can:722
end -- ./ecs/ecs.can:722
self:onUpdateEnd(dt) -- ./ecs/ecs.can:724
if self["interval"] then -- ./ecs/ecs.can:725
self["_waited"] = self["_waited"] - (self["interval"]) -- ./ecs/ecs.can:726
end -- ./ecs/ecs.can:726
end -- ./ecs/ecs.can:726
end, -- ./ecs/ecs.can:726
["draw"] = function(self) -- ./ecs/ecs.can:735
if self["visible"] then -- ./ecs/ecs.can:736
self:onDraw() -- ./ecs/ecs.can:737
if self["render"] ~= system_mt["render"] then -- ./ecs/ecs.can:738
for e in skipIter(self["_skiplist"]) do -- ./ecs/ecs.can:739
self:render(e, e[self["component"]]) -- ./ecs/ecs.can:740
end -- ./ecs/ecs.can:740
end -- ./ecs/ecs.can:740
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:743
s:draw() -- ./ecs/ecs.can:744
end -- ./ecs/ecs.can:744
self:onDrawEnd() -- ./ecs/ecs.can:746
end -- ./ecs/ecs.can:746
end, -- ./ecs/ecs.can:746
["callback"] = function(self, name, e, ...) -- ./ecs/ecs.can:761
if self["_has"][e] and self[name] then -- ./ecs/ecs.can:763
self[name](self, e, e[self["component"]], ...) -- ./ecs/ecs.can:764
end -- ./ecs/ecs.can:764
if self["_has"][e] then -- ./ecs/ecs.can:767
for _, ss in ipairs(self["systems"]) do -- ./ecs/ecs.can:768
ss:callback(name, e, ...) -- ./ecs/ecs.can:769
end -- ./ecs/ecs.can:769
end -- ./ecs/ecs.can:769
end, -- ./ecs/ecs.can:769
["emit"] = function(self, name, ...) -- ./ecs/ecs.can:795
local status -- ./ecs/ecs.can:797
if self[name] then -- ./ecs/ecs.can:798
status = self[name](self, ...) -- ./ecs/ecs.can:799
end -- ./ecs/ecs.can:799
if status ~= "stop" and status ~= "capture" then -- ./ecs/ecs.can:802
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:803
status = s:emit(name, ...) -- ./ecs/ecs.can:804
if status == "capture" then -- ./ecs/ecs.can:805
break -- ./ecs/ecs.can:805
end -- ./ecs/ecs.can:805
end -- ./ecs/ecs.can:805
end -- ./ecs/ecs.can:805
return status -- ./ecs/ecs.can:808
end, -- ./ecs/ecs.can:808
["destroy"] = function(self) -- ./ecs/ecs.can:812
recCallOnRemoveFromWorld(self["world"], { self }) -- ./ecs/ecs.can:813
recDestroySystems({ ["systems"] = { self } }) -- ./ecs/ecs.can:814
end -- ./ecs/ecs.can:814
} -- ./ecs/ecs.can:814
local alwaysTrue -- ./ecs/ecs.can:819
alwaysTrue = function() -- ./ecs/ecs.can:819
return true -- ./ecs/ecs.can:819
end -- ./ecs/ecs.can:819
local alwaysFalse -- ./ecs/ecs.can:820
alwaysFalse = function() -- ./ecs/ecs.can:820
return false -- ./ecs/ecs.can:820
end -- ./ecs/ecs.can:820
local recInstanciateSystems -- ./ecs/ecs.can:825
recInstanciateSystems = function(world, systems) -- ./ecs/ecs.can:825
local t -- ./ecs/ecs.can:826
t = {} -- ./ecs/ecs.can:826
for _, s in ipairs(systems) do -- ./ecs/ecs.can:827
local system -- ./ecs/ecs.can:828
system = setmetatable({ -- ./ecs/ecs.can:830
["systems"] = recInstanciateSystems(world, s["systems"] or {}), -- ./ecs/ecs.can:831
["world"] = world, -- ./ecs/ecs.can:832
["w"] = world, -- ./ecs/ecs.can:833
["s"] = world["s"], -- ./ecs/ecs.can:834
["_skiplist"] = skipNew() -- ./ecs/ecs.can:835
}, { ["__index"] = function(self, k) -- ./ecs/ecs.can:837
if s[k] ~= nil then -- ./ecs/ecs.can:838
return s[k] -- ./ecs/ecs.can:839
else -- ./ecs/ecs.can:839
return system_mt[k] -- ./ecs/ecs.can:841
end -- ./ecs/ecs.can:841
end }) -- ./ecs/ecs.can:841
system["_has"] = system["_skiplist"]["previous"][1] -- ./ecs/ecs.can:845
if type(s["filter"]) == "string" then -- ./ecs/ecs.can:847
system["filter"] = function(_, e) -- ./ecs/ecs.can:848
return e[s["filter"]] ~= nil -- ./ecs/ecs.can:848
end -- ./ecs/ecs.can:848
elseif type(s["filter"]) == "table" then -- ./ecs/ecs.can:849
system["filter"] = ecs["all"](unpack(s["filter"])) -- ./ecs/ecs.can:850
elseif type(s["filter"]) == "boolean" then -- ./ecs/ecs.can:851
if s["filter"] then -- ./ecs/ecs.can:852
system["filter"] = alwaysTrue -- ./ecs/ecs.can:853
else -- ./ecs/ecs.can:853
system["filter"] = alwaysFalse -- ./ecs/ecs.can:855
end -- ./ecs/ecs.can:855
end -- ./ecs/ecs.can:855
if not s["component"] and s["name"] then -- ./ecs/ecs.can:859
s["component"] = s["name"] -- ./ecs/ecs.can:860
end -- ./ecs/ecs.can:860
table["insert"](t, system) -- ./ecs/ecs.can:863
if s["name"] then -- ./ecs/ecs.can:864
world["s"][s["name"]] = system -- ./ecs/ecs.can:865
end -- ./ecs/ecs.can:865
system:onInstance() -- ./ecs/ecs.can:867
end -- ./ecs/ecs.can:867
return t -- ./ecs/ecs.can:869
end -- ./ecs/ecs.can:869
local recCallOnAddToWorld -- ./ecs/ecs.can:872
recCallOnAddToWorld = function(world, systems) -- ./ecs/ecs.can:872
for _, s in ipairs(systems) do -- ./ecs/ecs.can:873
recCallOnAddToWorld(world, s["systems"]) -- ./ecs/ecs.can:874
s:onAddToWorld(world) -- ./ecs/ecs.can:875
end -- ./ecs/ecs.can:875
end -- ./ecs/ecs.can:875
ecs = { -- ./ecs/ecs.can:881
["world"] = function(...) -- ./ecs/ecs.can:886
local world -- ./ecs/ecs.can:887
world = setmetatable({ -- ./ecs/ecs.can:887
["filter"] = ecs["all"](), -- ./ecs/ecs.can:888
["s"] = {}, -- ./ecs/ecs.can:889
["_skiplist"] = skipNew() -- ./ecs/ecs.can:890
}, { ["__index"] = system_mt }) -- ./ecs/ecs.can:891
world["_has"] = world["_skiplist"]["previous"][1] -- ./ecs/ecs.can:892
world["world"] = world -- ./ecs/ecs.can:893
world["w"] = world -- ./ecs/ecs.can:894
world["systems"] = recInstanciateSystems(world, { ... }) -- ./ecs/ecs.can:895
recCallOnAddToWorld(world, world["systems"]) -- ./ecs/ecs.can:896
return world -- ./ecs/ecs.can:897
end, -- ./ecs/ecs.can:897
["all"] = function(...) -- ./ecs/ecs.can:903
if ... then -- ./ecs/ecs.can:904
local l -- ./ecs/ecs.can:905
l = { ... } -- ./ecs/ecs.can:905
return function(s, e) -- ./ecs/ecs.can:906
for _, k in ipairs(l) do -- ./ecs/ecs.can:907
if e[k] == nil then -- ./ecs/ecs.can:908
return false -- ./ecs/ecs.can:909
end -- ./ecs/ecs.can:909
end -- ./ecs/ecs.can:909
return true -- ./ecs/ecs.can:912
end -- ./ecs/ecs.can:912
else -- ./ecs/ecs.can:912
return alwaysTrue -- ./ecs/ecs.can:915
end -- ./ecs/ecs.can:915
end, -- ./ecs/ecs.can:915
["any"] = function(...) -- ./ecs/ecs.can:922
if ... then -- ./ecs/ecs.can:923
local l -- ./ecs/ecs.can:924
l = { ... } -- ./ecs/ecs.can:924
return function(s, e) -- ./ecs/ecs.can:925
for _, k in ipairs(l) do -- ./ecs/ecs.can:926
if e[k] ~= nil then -- ./ecs/ecs.can:927
return true -- ./ecs/ecs.can:928
end -- ./ecs/ecs.can:928
end -- ./ecs/ecs.can:928
return false -- ./ecs/ecs.can:931
end -- ./ecs/ecs.can:931
else -- ./ecs/ecs.can:931
return alwaysFalse -- ./ecs/ecs.can:934
end -- ./ecs/ecs.can:934
end, -- ./ecs/ecs.can:934
["scene"] = function(name, systems, entities) -- ./ecs/ecs.can:952
if systems == nil then systems = {} end -- ./ecs/ecs.can:952
if entities == nil then entities = {} end -- ./ecs/ecs.can:952
assert(scene, "ubiquitousse.scene unavailable") -- ./ecs/ecs.can:953
local s -- ./ecs/ecs.can:954
s = scene["new"](name) -- ./ecs/ecs.can:954
local w -- ./ecs/ecs.can:955
s["enter"] = function(self) -- ./ecs/ecs.can:957
local sys, ent = systems, entities -- ./ecs/ecs.can:958
if type(systems) == "function" then -- ./ecs/ecs.can:959
sys = { systems() } -- ./ecs/ecs.can:959
end -- ./ecs/ecs.can:959
if type(entities) == "function" then -- ./ecs/ecs.can:960
ent = { entities() } -- ./ecs/ecs.can:960
end -- ./ecs/ecs.can:960
w = ecs["world"](unpack(sys)) -- ./ecs/ecs.can:961
w:add(unpack(ent)) -- ./ecs/ecs.can:962
end -- ./ecs/ecs.can:962
s["exit"] = function(self) -- ./ecs/ecs.can:964
w:destroy() -- ./ecs/ecs.can:965
end -- ./ecs/ecs.can:965
s["suspend"] = function(self) -- ./ecs/ecs.can:967
w:emit("onSuspend") -- ./ecs/ecs.can:968
end -- ./ecs/ecs.can:968
s["resume"] = function(self) -- ./ecs/ecs.can:970
w:emit("onResume") -- ./ecs/ecs.can:971
end -- ./ecs/ecs.can:971
s["update"] = function(self, dt) -- ./ecs/ecs.can:973
w:update(dt) -- ./ecs/ecs.can:974
end -- ./ecs/ecs.can:974
s["draw"] = function(self) -- ./ecs/ecs.can:976
w:draw() -- ./ecs/ecs.can:977
end -- ./ecs/ecs.can:977
return s -- ./ecs/ecs.can:980
end -- ./ecs/ecs.can:980
} -- ./ecs/ecs.can:980
return ecs -- ./ecs/ecs.can:984
