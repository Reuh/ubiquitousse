local signal -- ./signal/signal.can:30
local registry_mt -- ./signal/signal.can:36
registry_mt = { -- ./signal/signal.can:36
["signals"] = {}, -- ./signal/signal.can:39
["chained"] = {}, -- ./signal/signal.can:43
["bind"] = function(self, name, fn) -- ./signal/signal.can:48
assert(not self:has(name, fn), ("function %s already bound to signal %s"):format(fn, name)) -- ./signal/signal.can:49
if not self["signals"][name] then -- ./signal/signal.can:50
self["signals"][name] = {} -- ./signal/signal.can:51
end -- ./signal/signal.can:51
table["insert"](self["signals"][name], fn) -- ./signal/signal.can:53
return self -- ./signal/signal.can:54
end, -- ./signal/signal.can:54
["has"] = function(self, name, fn) -- ./signal/signal.can:60
if not self["signals"][name] then -- ./signal/signal.can:61
return false -- ./signal/signal.can:62
end -- ./signal/signal.can:62
for _, f in ipairs(self["signals"][name]) do -- ./signal/signal.can:64
if f == fn then -- ./signal/signal.can:65
return true -- ./signal/signal.can:66
end -- ./signal/signal.can:66
end -- ./signal/signal.can:66
return false -- ./signal/signal.can:69
end, -- ./signal/signal.can:69
["unbind"] = function(self, name, fn) -- ./signal/signal.can:75
if not self["signals"][name] then -- ./signal/signal.can:76
self["signals"][name] = {} -- ./signal/signal.can:77
end -- ./signal/signal.can:77
for i = # self["signals"][name], 1, - 1 do -- ./signal/signal.can:79
local f = self["signals"][name][i] -- ./signal/signal.can:80
if f == fn then -- ./signal/signal.can:81
table["remove"](self["signals"][name], i) -- ./signal/signal.can:82
return self -- ./signal/signal.can:83
end -- ./signal/signal.can:83
end -- ./signal/signal.can:83
error(("function %s not bound to signal %s"):format(fn, name)) -- ./signal/signal.can:86
end, -- ./signal/signal.can:86
["unbindPattern"] = function(self, pat, fn) -- ./signal/signal.can:91
return self:_patternize("unbind", pat, fn) -- ./signal/signal.can:92
end, -- ./signal/signal.can:92
["clear"] = function(self, name) -- ./signal/signal.can:97
self["signals"][name] = nil -- ./signal/signal.can:98
end, -- ./signal/signal.can:98
["clearPattern"] = function(self, pat) -- ./signal/signal.can:102
return self:_patternize("clear", pat) -- ./signal/signal.can:103
end, -- ./signal/signal.can:103
["emit"] = function(self, name, ...) -- ./signal/signal.can:109
if self["signals"][name] then -- ./signal/signal.can:110
for _, fn in ipairs(self["signals"][name]) do -- ./signal/signal.can:111
fn(...) -- ./signal/signal.can:112
end -- ./signal/signal.can:112
end -- ./signal/signal.can:112
for _, c in ipairs(self["chained"]) do -- ./signal/signal.can:115
c:emit(name, ...) -- ./signal/signal.can:116
end -- ./signal/signal.can:116
return self -- ./signal/signal.can:118
end, -- ./signal/signal.can:118
["emitPattern"] = function(self, pat, ...) -- ./signal/signal.can:123
return self:_patternize("emit", pat, ...) -- ./signal/signal.can:124
end, -- ./signal/signal.can:124
["chain"] = function(self, registry) -- ./signal/signal.can:131
if not registry then -- ./signal/signal.can:132
registry = signal["new"]() -- ./signal/signal.can:133
end -- ./signal/signal.can:133
table["insert"](self["chained"], registry) -- ./signal/signal.can:135
return registry -- ./signal/signal.can:136
end, -- ./signal/signal.can:136
["unchain"] = function(self, registry) -- ./signal/signal.can:141
for i = # self["chained"], 1, - 1 do -- ./signal/signal.can:142
if self["chained"][i] == registry then -- ./signal/signal.can:143
table["remove"](self["chained"], i) -- ./signal/signal.can:144
return self -- ./signal/signal.can:145
end -- ./signal/signal.can:145
end -- ./signal/signal.can:145
error("the givent registry is not chained with this registry") -- ./signal/signal.can:148
end, -- ./signal/signal.can:148
["_patternize"] = function(self, method, pat, ...) -- ./signal/signal.can:151
for name in pairs(self["signals"]) do -- ./signal/signal.can:152
if name:match(pat) then -- ./signal/signal.can:153
self[method](self, name, ...) -- ./signal/signal.can:154
end -- ./signal/signal.can:154
end -- ./signal/signal.can:154
end -- ./signal/signal.can:154
} -- ./signal/signal.can:154
registry_mt["__index"] = registry_mt -- ./signal/signal.can:159
local group_mt -- ./signal/signal.can:172
group_mt = { -- ./signal/signal.can:172
["paused"] = false, -- ./signal/signal.can:175
["binds"] = {}, -- ./signal/signal.can:179
["bind"] = function(self, registry, name, fn) -- ./signal/signal.can:187
table["insert"](self["binds"], { -- ./signal/signal.can:188
registry, -- ./signal/signal.can:188
name, -- ./signal/signal.can:188
fn -- ./signal/signal.can:188
}) -- ./signal/signal.can:188
if not self["paused"] then -- ./signal/signal.can:189
registry:bind(name, fn) -- ./signal/signal.can:189
end -- ./signal/signal.can:189
end, -- ./signal/signal.can:189
["clear"] = function(self) -- ./signal/signal.can:193
if not self["paused"] then -- ./signal/signal.can:194
for _, b in ipairs(self["binds"]) do -- ./signal/signal.can:195
b[1]:unbind(b[2], b[3]) -- ./signal/signal.can:196
end -- ./signal/signal.can:196
end -- ./signal/signal.can:196
self["binds"] = {} -- ./signal/signal.can:199
end, -- ./signal/signal.can:199
["pause"] = function(self) -- ./signal/signal.can:204
assert(not self["paused"], "event group is already paused") -- ./signal/signal.can:205
self["paused"] = true -- ./signal/signal.can:206
for _, b in ipairs(self["binds"]) do -- ./signal/signal.can:207
b[1]:unbind(b[2], b[3]) -- ./signal/signal.can:208
end -- ./signal/signal.can:208
end, -- ./signal/signal.can:208
["resume"] = function(self) -- ./signal/signal.can:214
assert(self["paused"], "event group is not paused") -- ./signal/signal.can:215
self["paused"] = false -- ./signal/signal.can:216
for _, b in ipairs(self["binds"]) do -- ./signal/signal.can:217
b[1]:bind(b[2], b[3]) -- ./signal/signal.can:218
end -- ./signal/signal.can:218
end -- ./signal/signal.can:218
} -- ./signal/signal.can:218
group_mt["__index"] = group_mt -- ./signal/signal.can:222
signal = { -- ./signal/signal.can:228
["new"] = function() -- ./signal/signal.can:231
return setmetatable({ -- ./signal/signal.can:232
["signals"] = {}, -- ./signal/signal.can:232
["chained"] = {} -- ./signal/signal.can:232
}, registry_mt) -- ./signal/signal.can:232
end, -- ./signal/signal.can:232
["group"] = function() -- ./signal/signal.can:237
return setmetatable({ ["binds"] = {} }, group_mt) -- ./signal/signal.can:238
end, -- ./signal/signal.can:238
["signals"] = {}, -- ./signal/signal.can:242
["bind"] = function(...) -- ./signal/signal.can:243
return registry_mt["bind"](signal, ...) -- ./signal/signal.can:244
end, -- ./signal/signal.can:244
["has"] = function(...) -- ./signal/signal.can:246
return registry_mt["has"](signal, ...) -- ./signal/signal.can:247
end, -- ./signal/signal.can:247
["unbind"] = function(...) -- ./signal/signal.can:249
return registry_mt["unbind"](signal, ...) -- ./signal/signal.can:250
end, -- ./signal/signal.can:250
["unbindPattern"] = function(...) -- ./signal/signal.can:252
return registry_mt["unbindPattern"](signal, ...) -- ./signal/signal.can:253
end, -- ./signal/signal.can:253
["clear"] = function(...) -- ./signal/signal.can:255
return registry_mt["clear"](signal, ...) -- ./signal/signal.can:256
end, -- ./signal/signal.can:256
["clearPattern"] = function(...) -- ./signal/signal.can:258
return registry_mt["clearPattern"](signal, ...) -- ./signal/signal.can:259
end, -- ./signal/signal.can:259
["emit"] = function(...) -- ./signal/signal.can:261
return registry_mt["emit"](signal, ...) -- ./signal/signal.can:262
end, -- ./signal/signal.can:262
["emitPattern"] = function(...) -- ./signal/signal.can:264
return registry_mt["emitPattern"](signal, ...) -- ./signal/signal.can:265
end, -- ./signal/signal.can:265
["event"] = nil, -- ./signal/signal.can:286
["registerEvents"] = function() -- ./signal/signal.can:291
local callbacks = { -- ./signal/signal.can:292
"displayrotated", -- ./signal/signal.can:293
"draw", -- ./signal/signal.can:293
"load", -- ./signal/signal.can:293
"lowmemory", -- ./signal/signal.can:293
"quit", -- ./signal/signal.can:293
"update", -- ./signal/signal.can:293
"directorydropped", -- ./signal/signal.can:294
"filedropped", -- ./signal/signal.can:294
"focus", -- ./signal/signal.can:294
"mousefocus", -- ./signal/signal.can:294
"resize", -- ./signal/signal.can:294
"visible", -- ./signal/signal.can:294
"keypressed", -- ./signal/signal.can:295
"keyreleased", -- ./signal/signal.can:295
"textedited", -- ./signal/signal.can:295
"textinput", -- ./signal/signal.can:295
"mousemoved", -- ./signal/signal.can:296
"mousepressed", -- ./signal/signal.can:296
"mousereleased", -- ./signal/signal.can:296
"wheelmoved", -- ./signal/signal.can:296
"gamepadaxis", -- ./signal/signal.can:297
"gamepadpressed", -- ./signal/signal.can:297
"gamepadreleased", -- ./signal/signal.can:297
"joystickadded", -- ./signal/signal.can:298
"joystickaxis", -- ./signal/signal.can:298
"joystickhat", -- ./signal/signal.can:298
"joystickpressed", -- ./signal/signal.can:298
"joystickreleased", -- ./signal/signal.can:298
"joystickremoved", -- ./signal/signal.can:298
"touchmoved", -- ./signal/signal.can:299
"touchpressed", -- ./signal/signal.can:299
"touchreleased" -- ./signal/signal.can:299
} -- ./signal/signal.can:299
local event = signal["event"] -- ./signal/signal.can:301
for _, callback in ipairs(callbacks) do -- ./signal/signal.can:302
if callback == "update" then -- ./signal/signal.can:303
if love[callback] then -- ./signal/signal.can:304
local old = love[callback] -- ./signal/signal.can:305
love[callback] = function(dt) -- ./signal/signal.can:306
old(dt) -- ./signal/signal.can:307
event:emit(callback, dt) -- ./signal/signal.can:308
end -- ./signal/signal.can:308
else -- ./signal/signal.can:308
love[callback] = function(dt) -- ./signal/signal.can:311
event:emit(callback, dt) -- ./signal/signal.can:312
end -- ./signal/signal.can:312
end -- ./signal/signal.can:312
else -- ./signal/signal.can:312
if love[callback] then -- ./signal/signal.can:316
local old = love[callback] -- ./signal/signal.can:317
love[callback] = function(...) -- ./signal/signal.can:318
old(...) -- ./signal/signal.can:319
event:emit(callback, ...) -- ./signal/signal.can:320
end -- ./signal/signal.can:320
else -- ./signal/signal.can:320
love[callback] = function(...) -- ./signal/signal.can:323
event:emit(callback, ...) -- ./signal/signal.can:324
end -- ./signal/signal.can:324
end -- ./signal/signal.can:324
end -- ./signal/signal.can:324
end -- ./signal/signal.can:324
end -- ./signal/signal.can:324
} -- ./signal/signal.can:324
signal["event"] = signal["new"]() -- ./signal/signal.can:332
return signal -- ./signal/signal.can:334
