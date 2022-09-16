local loaded, scene -- ./ecs/ecs.can:51
if ... then -- ./ecs/ecs.can:52
loaded, scene = pcall(require, (...):match("^(.-)ecs") .. "scene") -- ./ecs/ecs.can:52
end -- ./ecs/ecs.can:52
if not loaded then -- ./ecs/ecs.can:53
scene = nil -- ./ecs/ecs.can:53
end -- ./ecs/ecs.can:53
local ecs -- ./ecs/ecs.can:55
local recDestroySystems -- ./ecs/ecs.can:102
recDestroySystems = function(system) -- ./ecs/ecs.can:102
for i = # system["systems"], 1, - 1 do -- ./ecs/ecs.can:103
local s -- ./ecs/ecs.can:104
s = system["systems"][i] -- ./ecs/ecs.can:104
recDestroySystems(s) -- ./ecs/ecs.can:105
s:onDestroy() -- ./ecs/ecs.can:106
system["systems"][i] = nil -- ./ecs/ecs.can:107
if s["name"] then -- ./ecs/ecs.can:108
system["world"]["s"][s["name"]] = nil -- ./ecs/ecs.can:109
end -- ./ecs/ecs.can:109
end -- ./ecs/ecs.can:109
end -- ./ecs/ecs.can:109
local recCallOnRemoveFromWorld -- ./ecs/ecs.can:114
recCallOnRemoveFromWorld = function(world, systems) -- ./ecs/ecs.can:114
for _, s in ipairs(systems) do -- ./ecs/ecs.can:115
s:clear() -- ./ecs/ecs.can:116
recCallOnRemoveFromWorld(world, s["systems"]) -- ./ecs/ecs.can:117
s:onRemoveFromWorld(world) -- ./ecs/ecs.can:118
end -- ./ecs/ecs.can:118
end -- ./ecs/ecs.can:118
local nextEntity -- ./ecs/ecs.can:123
nextEntity = function(s) -- ./ecs/ecs.can:123
if s[1] then -- ./ecs/ecs.can:124
local var -- ./ecs/ecs.can:125
var = s[1][1] -- ./ecs/ecs.can:125
s[1] = s[1][2] -- ./ecs/ecs.can:126
return var -- ./ecs/ecs.can:127
else -- ./ecs/ecs.can:127
return nil -- ./ecs/ecs.can:129
end -- ./ecs/ecs.can:129
end -- ./ecs/ecs.can:129
local copy -- ./ecs/ecs.can:135
copy = function(a, b, cache) -- ./ecs/ecs.can:135
if cache == nil then cache = {} end -- ./ecs/ecs.can:135
for k, v in pairs(a) do -- ./ecs/ecs.can:136
if type(v) == "table" then -- ./ecs/ecs.can:137
if b[k] == nil then -- ./ecs/ecs.can:138
if cache[v] then -- ./ecs/ecs.can:139
b[k] = cache[v] -- ./ecs/ecs.can:140
else -- ./ecs/ecs.can:140
cache[v] = {} -- ./ecs/ecs.can:142
b[k] = cache[v] -- ./ecs/ecs.can:143
copy(v, b[k], cache) -- ./ecs/ecs.can:144
setmetatable(b[k], getmetatable(v)) -- ./ecs/ecs.can:145
end -- ./ecs/ecs.can:145
elseif type(b[k]) == "table" then -- ./ecs/ecs.can:147
copy(v, b[k], cache) -- ./ecs/ecs.can:148
end -- ./ecs/ecs.can:148
elseif b[k] == nil then -- ./ecs/ecs.can:150
b[k] = v -- ./ecs/ecs.can:151
end -- ./ecs/ecs.can:151
end -- ./ecs/ecs.can:151
end -- ./ecs/ecs.can:151
local system_mt -- ./ecs/ecs.can:217
system_mt = { -- ./ecs/ecs.can:217
["name"] = nil, -- ./ecs/ecs.can:231
["systems"] = nil, -- ./ecs/ecs.can:239
["interval"] = false, -- ./ecs/ecs.can:245
["active"] = true, -- ./ecs/ecs.can:249
["visible"] = true, -- ./ecs/ecs.can:253
["component"] = nil, -- ./ecs/ecs.can:260
["default"] = nil, -- ./ecs/ecs.can:270
["filter"] = function(self, e) -- ./ecs/ecs.can:291
return false -- ./ecs/ecs.can:291
end, -- ./ecs/ecs.can:291
["compare"] = function(self, e1, e2) -- ./ecs/ecs.can:303
return true -- ./ecs/ecs.can:303
end, -- ./ecs/ecs.can:303
["onAdd"] = function(self, e, c) -- ./ecs/ecs.can:309
 -- ./ecs/ecs.can:309
end, -- ./ecs/ecs.can:309
["onRemove"] = function(self, e, c) -- ./ecs/ecs.can:314
 -- ./ecs/ecs.can:314
end, -- ./ecs/ecs.can:314
["onInstance"] = function(self) -- ./ecs/ecs.can:317
 -- ./ecs/ecs.can:317
end, -- ./ecs/ecs.can:317
["onAddToWorld"] = function(self, world) -- ./ecs/ecs.can:321
 -- ./ecs/ecs.can:321
end, -- ./ecs/ecs.can:321
["onRemoveFromWorld"] = function(self, world) -- ./ecs/ecs.can:325
 -- ./ecs/ecs.can:325
end, -- ./ecs/ecs.can:325
["onDestroy"] = function(self) -- ./ecs/ecs.can:328
 -- ./ecs/ecs.can:328
end, -- ./ecs/ecs.can:328
["onUpdate"] = function(self, dt) -- ./ecs/ecs.can:333
 -- ./ecs/ecs.can:333
end, -- ./ecs/ecs.can:333
["onDraw"] = function(self) -- ./ecs/ecs.can:337
 -- ./ecs/ecs.can:337
end, -- ./ecs/ecs.can:337
["process"] = function(self, e, c, dt) -- ./ecs/ecs.can:344
 -- ./ecs/ecs.can:344
end, -- ./ecs/ecs.can:344
["render"] = function(self, e, c) -- ./ecs/ecs.can:350
 -- ./ecs/ecs.can:350
end, -- ./ecs/ecs.can:350
["onUpdateEnd"] = function(self, dt) -- ./ecs/ecs.can:355
 -- ./ecs/ecs.can:355
end, -- ./ecs/ecs.can:355
["onDrawEnd"] = function(self) -- ./ecs/ecs.can:359
 -- ./ecs/ecs.can:359
end, -- ./ecs/ecs.can:359
["world"] = nil, -- ./ecs/ecs.can:369
["w"] = nil, -- ./ecs/ecs.can:373
["entityCount"] = 0, -- ./ecs/ecs.can:377
["s"] = nil, -- ./ecs/ecs.can:381
["_first"] = nil, -- ./ecs/ecs.can:387
["_previous"] = nil, -- ./ecs/ecs.can:391
["_waited"] = 0, -- ./ecs/ecs.can:394
["add"] = function(self, e, ...) -- ./ecs/ecs.can:415
if e ~= nil and not self["_previous"][e] and self:filter(e) then -- ./ecs/ecs.can:416
if self["component"] and self["default"] then -- ./ecs/ecs.can:418
copy({ [self["component"]] = self["default"] }, e) -- ./ecs/ecs.can:419
end -- ./ecs/ecs.can:419
if self["_first"] == nil then -- ./ecs/ecs.can:422
self["_first"] = { -- ./ecs/ecs.can:423
e, -- ./ecs/ecs.can:423
nil -- ./ecs/ecs.can:423
} -- ./ecs/ecs.can:423
self["_previous"][e] = true -- ./ecs/ecs.can:424
elseif self:compare(e, self["_first"][1]) then -- ./ecs/ecs.can:425
local nxt -- ./ecs/ecs.can:426
nxt = self["_first"] -- ./ecs/ecs.can:426
self["_first"] = { -- ./ecs/ecs.can:427
e, -- ./ecs/ecs.can:427
nxt -- ./ecs/ecs.can:427
} -- ./ecs/ecs.can:427
self["_previous"][e] = true -- ./ecs/ecs.can:428
self["_previous"][nxt[1]] = self["_first"] -- ./ecs/ecs.can:429
else -- ./ecs/ecs.can:429
local entity -- ./ecs/ecs.can:431
entity = self["_first"] -- ./ecs/ecs.can:431
while entity[2] ~= nil do -- ./ecs/ecs.can:432
if self:compare(e, entity[2][1]) then -- ./ecs/ecs.can:433
local nxt -- ./ecs/ecs.can:434
nxt = entity[2] -- ./ecs/ecs.can:434
entity[2] = { -- ./ecs/ecs.can:435
e, -- ./ecs/ecs.can:435
nxt -- ./ecs/ecs.can:435
} -- ./ecs/ecs.can:435
self["_previous"][e] = entity -- ./ecs/ecs.can:436
self["_previous"][nxt[1]] = entity[2] -- ./ecs/ecs.can:437
break -- ./ecs/ecs.can:438
end -- ./ecs/ecs.can:438
entity = entity[2] -- ./ecs/ecs.can:440
end -- ./ecs/ecs.can:440
if entity[2] == nil then -- ./ecs/ecs.can:442
entity[2] = { -- ./ecs/ecs.can:443
e, -- ./ecs/ecs.can:443
nil -- ./ecs/ecs.can:443
} -- ./ecs/ecs.can:443
self["_previous"][e] = entity -- ./ecs/ecs.can:444
end -- ./ecs/ecs.can:444
end -- ./ecs/ecs.can:444
self["entityCount"] = self["entityCount"] + (1) -- ./ecs/ecs.can:448
self:onAdd(e, e[self["component"]]) -- ./ecs/ecs.can:449
if self["_previous"][e] then -- ./ecs/ecs.can:451
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:452
s:add(e) -- ./ecs/ecs.can:453
end -- ./ecs/ecs.can:453
end -- ./ecs/ecs.can:453
end -- ./ecs/ecs.can:453
if ... then -- ./ecs/ecs.can:457
return e, self:add(...) -- ./ecs/ecs.can:458
else -- ./ecs/ecs.can:458
return e -- ./ecs/ecs.can:460
end -- ./ecs/ecs.can:460
end, -- ./ecs/ecs.can:460
["remove"] = function(self, e, ...) -- ./ecs/ecs.can:475
if e ~= nil then -- ./ecs/ecs.can:476
if self["_previous"][e] then -- ./ecs/ecs.can:477
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:479
s:remove(e) -- ./ecs/ecs.can:480
end -- ./ecs/ecs.can:480
end -- ./ecs/ecs.can:480
if self["_previous"][e] then -- ./ecs/ecs.can:483
local prev -- ./ecs/ecs.can:485
prev = self["_previous"][e] -- ./ecs/ecs.can:485
if prev == true then -- ./ecs/ecs.can:486
self["_first"] = self["_first"][2] -- ./ecs/ecs.can:487
if self["_first"] then -- ./ecs/ecs.can:488
self["_previous"][self["_first"][1]] = true -- ./ecs/ecs.can:489
end -- ./ecs/ecs.can:489
else -- ./ecs/ecs.can:489
prev[2] = prev[2][2] -- ./ecs/ecs.can:492
if prev[2] then -- ./ecs/ecs.can:493
self["_previous"][prev[2][1]] = prev -- ./ecs/ecs.can:494
end -- ./ecs/ecs.can:494
end -- ./ecs/ecs.can:494
self["_previous"][e] = nil -- ./ecs/ecs.can:498
self["entityCount"] = self["entityCount"] - (1) -- ./ecs/ecs.can:499
self:onRemove(e, e[self["component"]]) -- ./ecs/ecs.can:500
end -- ./ecs/ecs.can:500
end -- ./ecs/ecs.can:500
if ... then -- ./ecs/ecs.can:503
return e, self:remove(...) -- ./ecs/ecs.can:504
else -- ./ecs/ecs.can:504
return e -- ./ecs/ecs.can:506
end -- ./ecs/ecs.can:506
end, -- ./ecs/ecs.can:506
["refresh"] = function(self, e, ...) -- ./ecs/ecs.can:518
if e ~= nil then -- ./ecs/ecs.can:519
if not self["_previous"][e] then -- ./ecs/ecs.can:520
self:add(e) -- ./ecs/ecs.can:521
elseif self["_previous"][e] then -- ./ecs/ecs.can:522
if not self:filter(e) then -- ./ecs/ecs.can:523
self:remove(e) -- ./ecs/ecs.can:524
else -- ./ecs/ecs.can:524
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:526
s:refresh(e) -- ./ecs/ecs.can:527
end -- ./ecs/ecs.can:527
end -- ./ecs/ecs.can:527
end -- ./ecs/ecs.can:527
end -- ./ecs/ecs.can:527
if ... then -- ./ecs/ecs.can:532
return e, self:refresh(...) -- ./ecs/ecs.can:533
else -- ./ecs/ecs.can:533
return e -- ./ecs/ecs.can:535
end -- ./ecs/ecs.can:535
end, -- ./ecs/ecs.can:535
["reorder"] = function(self, e, ...) -- ./ecs/ecs.can:547
if e ~= nil then -- ./ecs/ecs.can:548
if self["_previous"][e] then -- ./ecs/ecs.can:549
local prev -- ./ecs/ecs.can:550
prev = self["_previous"][e] -- ./ecs/ecs.can:550
local next -- ./ecs/ecs.can:551
next = prev == true and self["_first"][2] or prev[2][2] -- ./ecs/ecs.can:551
if prev == true then -- ./ecs/ecs.can:553
self["_first"] = self["_first"][2] -- ./ecs/ecs.can:554
else -- ./ecs/ecs.can:554
prev[2] = next -- ./ecs/ecs.can:556
end -- ./ecs/ecs.can:556
if next then -- ./ecs/ecs.can:558
self["_previous"][next[1]] = prev -- ./ecs/ecs.can:559
end -- ./ecs/ecs.can:559
while prev ~= true and self:compare(e, prev[1]) do -- ./ecs/ecs.can:562
next = prev -- ./ecs/ecs.can:563
prev = self["_previous"][prev[1]] -- ./ecs/ecs.can:564
end -- ./ecs/ecs.can:564
while next ~= nil and not self:compare(e, next[1]) do -- ./ecs/ecs.can:566
prev = next -- ./ecs/ecs.can:567
next = next[2] -- ./ecs/ecs.can:568
end -- ./ecs/ecs.can:568
local new -- ./ecs/ecs.can:571
new = { -- ./ecs/ecs.can:571
e, -- ./ecs/ecs.can:571
next -- ./ecs/ecs.can:571
} -- ./ecs/ecs.can:571
self["_previous"][e] = prev -- ./ecs/ecs.can:572
if next then -- ./ecs/ecs.can:573
self["_previous"][next[1]] = new -- ./ecs/ecs.can:574
end -- ./ecs/ecs.can:574
if prev == true then -- ./ecs/ecs.can:576
self["_first"] = new -- ./ecs/ecs.can:577
else -- ./ecs/ecs.can:577
prev[2] = new -- ./ecs/ecs.can:579
end -- ./ecs/ecs.can:579
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:582
s:reorder(e) -- ./ecs/ecs.can:583
end -- ./ecs/ecs.can:583
end -- ./ecs/ecs.can:583
end -- ./ecs/ecs.can:583
if ... then -- ./ecs/ecs.can:587
return e, self:reorder(...) -- ./ecs/ecs.can:588
else -- ./ecs/ecs.can:588
return e -- ./ecs/ecs.can:590
end -- ./ecs/ecs.can:590
end, -- ./ecs/ecs.can:590
["has"] = function(self, e, ...) -- ./ecs/ecs.can:599
local has -- ./ecs/ecs.can:600
has = e == nil or not not self["_previous"][e] -- ./ecs/ecs.can:600
if ... then -- ./ecs/ecs.can:601
return has and self:has(...) -- ./ecs/ecs.can:602
else -- ./ecs/ecs.can:602
return has -- ./ecs/ecs.can:604
end -- ./ecs/ecs.can:604
end, -- ./ecs/ecs.can:604
["iter"] = function(self) -- ./ecs/ecs.can:609
return nextEntity, { self["_first"] } -- ./ecs/ecs.can:610
end, -- ./ecs/ecs.can:610
["get"] = function(self, i) -- ./ecs/ecs.can:617
local n = 1 -- ./ecs/ecs.can:618
for e in self:iter() do -- ./ecs/ecs.can:619
if n == i then -- ./ecs/ecs.can:620
return e -- ./ecs/ecs.can:621
end -- ./ecs/ecs.can:621
n = n + (1) -- ./ecs/ecs.can:623
end -- ./ecs/ecs.can:623
return nil -- ./ecs/ecs.can:625
end, -- ./ecs/ecs.can:625
["clear"] = function(self) -- ./ecs/ecs.can:628
for e in self:iter() do -- ./ecs/ecs.can:629
self:remove(e) -- ./ecs/ecs.can:630
end -- ./ecs/ecs.can:630
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:632
s:clear() -- ./ecs/ecs.can:633
end -- ./ecs/ecs.can:633
end, -- ./ecs/ecs.can:633
["update"] = function(self, dt) -- ./ecs/ecs.can:640
if self["active"] then -- ./ecs/ecs.can:641
if self["interval"] then -- ./ecs/ecs.can:642
self["_waited"] = self["_waited"] + (dt) -- ./ecs/ecs.can:643
if self["_waited"] < self["interval"] then -- ./ecs/ecs.can:644
return  -- ./ecs/ecs.can:645
end -- ./ecs/ecs.can:645
end -- ./ecs/ecs.can:645
self:onUpdate(dt) -- ./ecs/ecs.can:648
if self["process"] ~= system_mt["process"] then -- ./ecs/ecs.can:649
for e in self:iter() do -- ./ecs/ecs.can:650
self:process(e, e[self["component"]], dt) -- ./ecs/ecs.can:651
end -- ./ecs/ecs.can:651
end -- ./ecs/ecs.can:651
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:654
s:update(dt) -- ./ecs/ecs.can:655
end -- ./ecs/ecs.can:655
self:onUpdateEnd(dt) -- ./ecs/ecs.can:657
if self["interval"] then -- ./ecs/ecs.can:658
self["_waited"] = self["_waited"] - (self["interval"]) -- ./ecs/ecs.can:659
end -- ./ecs/ecs.can:659
end -- ./ecs/ecs.can:659
end, -- ./ecs/ecs.can:659
["draw"] = function(self) -- ./ecs/ecs.can:666
if self["visible"] then -- ./ecs/ecs.can:667
self:onDraw() -- ./ecs/ecs.can:668
if self["render"] ~= system_mt["render"] then -- ./ecs/ecs.can:669
for e in self:iter() do -- ./ecs/ecs.can:670
self:render(e, e[self["component"]]) -- ./ecs/ecs.can:671
end -- ./ecs/ecs.can:671
end -- ./ecs/ecs.can:671
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:674
s:draw() -- ./ecs/ecs.can:675
end -- ./ecs/ecs.can:675
self:onDrawEnd() -- ./ecs/ecs.can:677
end -- ./ecs/ecs.can:677
end, -- ./ecs/ecs.can:677
["callback"] = function(self, name, e, ...) -- ./ecs/ecs.can:690
if self["_previous"][e] and self[name] then -- ./ecs/ecs.can:692
self[name](self, e, e[self["component"]], ...) -- ./ecs/ecs.can:693
end -- ./ecs/ecs.can:693
if self["_previous"][e] then -- ./ecs/ecs.can:696
for _, ss in ipairs(self["systems"]) do -- ./ecs/ecs.can:697
ss:callback(name, e, ...) -- ./ecs/ecs.can:698
end -- ./ecs/ecs.can:698
end -- ./ecs/ecs.can:698
end, -- ./ecs/ecs.can:698
["emit"] = function(self, name, ...) -- ./ecs/ecs.can:723
local status -- ./ecs/ecs.can:725
if self[name] then -- ./ecs/ecs.can:726
status = self[name](self, ...) -- ./ecs/ecs.can:727
end -- ./ecs/ecs.can:727
if status ~= "stop" and status ~= "capture" then -- ./ecs/ecs.can:730
for _, s in ipairs(self["systems"]) do -- ./ecs/ecs.can:731
status = s:emit(name, ...) -- ./ecs/ecs.can:732
if status == "capture" then -- ./ecs/ecs.can:733
break -- ./ecs/ecs.can:733
end -- ./ecs/ecs.can:733
end -- ./ecs/ecs.can:733
end -- ./ecs/ecs.can:733
return status -- ./ecs/ecs.can:736
end, -- ./ecs/ecs.can:736
["destroy"] = function(self) -- ./ecs/ecs.can:739
recCallOnRemoveFromWorld(self["world"], { self }) -- ./ecs/ecs.can:740
recDestroySystems({ ["systems"] = { self } }) -- ./ecs/ecs.can:741
end -- ./ecs/ecs.can:741
} -- ./ecs/ecs.can:741
local alwaysTrue -- ./ecs/ecs.can:746
alwaysTrue = function() -- ./ecs/ecs.can:746
return true -- ./ecs/ecs.can:746
end -- ./ecs/ecs.can:746
local alwaysFalse -- ./ecs/ecs.can:747
alwaysFalse = function() -- ./ecs/ecs.can:747
return false -- ./ecs/ecs.can:747
end -- ./ecs/ecs.can:747
local recInstanciateSystems -- ./ecs/ecs.can:752
recInstanciateSystems = function(world, systems) -- ./ecs/ecs.can:752
local t -- ./ecs/ecs.can:753
t = {} -- ./ecs/ecs.can:753
for _, s in ipairs(systems) do -- ./ecs/ecs.can:754
local system -- ./ecs/ecs.can:755
system = setmetatable({ -- ./ecs/ecs.can:757
["systems"] = recInstanciateSystems(world, s["systems"] or {}), -- ./ecs/ecs.can:758
["world"] = world, -- ./ecs/ecs.can:759
["w"] = world, -- ./ecs/ecs.can:760
["s"] = world["s"], -- ./ecs/ecs.can:761
["_previous"] = {} -- ./ecs/ecs.can:762
}, { ["__index"] = function(self, k) -- ./ecs/ecs.can:764
if s[k] ~= nil then -- ./ecs/ecs.can:765
return s[k] -- ./ecs/ecs.can:766
else -- ./ecs/ecs.can:766
return system_mt[k] -- ./ecs/ecs.can:768
end -- ./ecs/ecs.can:768
end }) -- ./ecs/ecs.can:768
if type(s["filter"]) == "string" then -- ./ecs/ecs.can:773
system["filter"] = function(_, e) -- ./ecs/ecs.can:774
return e[s["filter"]] ~= nil -- ./ecs/ecs.can:774
end -- ./ecs/ecs.can:774
elseif type(s["filter"]) == "table" then -- ./ecs/ecs.can:775
system["filter"] = ecs["all"](unpack(s["filter"])) -- ./ecs/ecs.can:776
elseif type(s["filter"]) == "boolean" then -- ./ecs/ecs.can:777
if s["filter"] then -- ./ecs/ecs.can:778
system["filter"] = alwaysTrue -- ./ecs/ecs.can:779
else -- ./ecs/ecs.can:779
system["filter"] = alwaysFalse -- ./ecs/ecs.can:781
end -- ./ecs/ecs.can:781
end -- ./ecs/ecs.can:781
if not s["component"] and s["name"] then -- ./ecs/ecs.can:785
s["component"] = s["name"] -- ./ecs/ecs.can:786
end -- ./ecs/ecs.can:786
table["insert"](t, system) -- ./ecs/ecs.can:789
if s["name"] then -- ./ecs/ecs.can:790
world["s"][s["name"]] = system -- ./ecs/ecs.can:791
end -- ./ecs/ecs.can:791
system:onInstance() -- ./ecs/ecs.can:793
end -- ./ecs/ecs.can:793
return t -- ./ecs/ecs.can:795
end -- ./ecs/ecs.can:795
local recCallOnAddToWorld -- ./ecs/ecs.can:798
recCallOnAddToWorld = function(world, systems) -- ./ecs/ecs.can:798
for _, s in ipairs(systems) do -- ./ecs/ecs.can:799
recCallOnAddToWorld(world, s["systems"]) -- ./ecs/ecs.can:800
s:onAddToWorld(world) -- ./ecs/ecs.can:801
end -- ./ecs/ecs.can:801
end -- ./ecs/ecs.can:801
ecs = { -- ./ecs/ecs.can:807
["world"] = function(...) -- ./ecs/ecs.can:812
local world -- ./ecs/ecs.can:813
world = setmetatable({ -- ./ecs/ecs.can:813
["filter"] = ecs["all"](), -- ./ecs/ecs.can:814
["s"] = {}, -- ./ecs/ecs.can:815
["_previous"] = {} -- ./ecs/ecs.can:816
}, { ["__index"] = system_mt }) -- ./ecs/ecs.can:817
world["world"] = world -- ./ecs/ecs.can:818
world["w"] = world -- ./ecs/ecs.can:819
world["systems"] = recInstanciateSystems(world, { ... }) -- ./ecs/ecs.can:820
recCallOnAddToWorld(world, world["systems"]) -- ./ecs/ecs.can:821
return world -- ./ecs/ecs.can:822
end, -- ./ecs/ecs.can:822
["all"] = function(...) -- ./ecs/ecs.can:828
if ... then -- ./ecs/ecs.can:829
local l -- ./ecs/ecs.can:830
l = { ... } -- ./ecs/ecs.can:830
return function(s, e) -- ./ecs/ecs.can:831
for _, k in ipairs(l) do -- ./ecs/ecs.can:832
if e[k] == nil then -- ./ecs/ecs.can:833
return false -- ./ecs/ecs.can:834
end -- ./ecs/ecs.can:834
end -- ./ecs/ecs.can:834
return true -- ./ecs/ecs.can:837
end -- ./ecs/ecs.can:837
else -- ./ecs/ecs.can:837
return alwaysTrue -- ./ecs/ecs.can:840
end -- ./ecs/ecs.can:840
end, -- ./ecs/ecs.can:840
["any"] = function(...) -- ./ecs/ecs.can:847
if ... then -- ./ecs/ecs.can:848
local l -- ./ecs/ecs.can:849
l = { ... } -- ./ecs/ecs.can:849
return function(s, e) -- ./ecs/ecs.can:850
for _, k in ipairs(l) do -- ./ecs/ecs.can:851
if e[k] ~= nil then -- ./ecs/ecs.can:852
return true -- ./ecs/ecs.can:853
end -- ./ecs/ecs.can:853
end -- ./ecs/ecs.can:853
return false -- ./ecs/ecs.can:856
end -- ./ecs/ecs.can:856
else -- ./ecs/ecs.can:856
return alwaysFalse -- ./ecs/ecs.can:859
end -- ./ecs/ecs.can:859
end, -- ./ecs/ecs.can:859
["scene"] = function(name, systems, entities) -- ./ecs/ecs.can:877
if systems == nil then systems = {} end -- ./ecs/ecs.can:877
if entities == nil then entities = {} end -- ./ecs/ecs.can:877
assert(scene, "ubiquitousse.scene unavailable") -- ./ecs/ecs.can:878
local s -- ./ecs/ecs.can:879
s = scene["new"](name) -- ./ecs/ecs.can:879
local w -- ./ecs/ecs.can:880
s["enter"] = function(self) -- ./ecs/ecs.can:882
local sys, ent = systems, entities -- ./ecs/ecs.can:883
if type(systems) == "function" then -- ./ecs/ecs.can:884
sys = { systems() } -- ./ecs/ecs.can:884
end -- ./ecs/ecs.can:884
if type(entities) == "function" then -- ./ecs/ecs.can:885
ent = { entities() } -- ./ecs/ecs.can:885
end -- ./ecs/ecs.can:885
w = ecs["world"](unpack(sys)) -- ./ecs/ecs.can:886
w:add(unpack(ent)) -- ./ecs/ecs.can:887
end -- ./ecs/ecs.can:887
s["exit"] = function(self) -- ./ecs/ecs.can:889
w:destroy() -- ./ecs/ecs.can:890
end -- ./ecs/ecs.can:890
s["suspend"] = function(self) -- ./ecs/ecs.can:892
w:emit("onSuspend") -- ./ecs/ecs.can:893
end -- ./ecs/ecs.can:893
s["resume"] = function(self) -- ./ecs/ecs.can:895
w:emit("onResume") -- ./ecs/ecs.can:896
end -- ./ecs/ecs.can:896
s["update"] = function(self, dt) -- ./ecs/ecs.can:898
w:update(dt) -- ./ecs/ecs.can:899
end -- ./ecs/ecs.can:899
s["draw"] = function(self) -- ./ecs/ecs.can:901
w:draw() -- ./ecs/ecs.can:902
end -- ./ecs/ecs.can:902
return s -- ./ecs/ecs.can:905
end -- ./ecs/ecs.can:905
} -- ./ecs/ecs.can:905
return ecs -- ./ecs/ecs.can:909
