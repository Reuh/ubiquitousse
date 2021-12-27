local registry_mt -- ./signal/signal.can:13
registry_mt = { -- ./signal/signal.can:13
["signals"] = {}, -- ./signal/signal.can:16
["bind"] = function(self, name, fn, ...) -- ./signal/signal.can:22
if not self["signals"][name] then -- ./signal/signal.can:23
self["signals"][name] = {} -- ./signal/signal.can:24
end -- ./signal/signal.can:24
table["insert"](self["signals"][name], fn) -- ./signal/signal.can:26
if ... then -- ./signal/signal.can:27
self:bind(name, ...) -- ./signal/signal.can:28
end -- ./signal/signal.can:28
end, -- ./signal/signal.can:28
["unbind"] = function(self, name, fn, ...) -- ./signal/signal.can:36
if not self["signals"][name] then -- ./signal/signal.can:37
return  -- ./signal/signal.can:38
end -- ./signal/signal.can:38
for i = # self["signals"][name], 1, - 1 do -- ./signal/signal.can:40
if self["signals"][name] == fn then -- ./signal/signal.can:41
table["remove"](self["signals"][name], i) -- ./signal/signal.can:42
end -- ./signal/signal.can:42
end -- ./signal/signal.can:42
if ... then -- ./signal/signal.can:45
self:unbind(name, ...) -- ./signal/signal.can:46
end -- ./signal/signal.can:46
end, -- ./signal/signal.can:46
["unbindAll"] = function(self, name) -- ./signal/signal.can:52
self["signals"][name] = nil -- ./signal/signal.can:53
end, -- ./signal/signal.can:53
["replace"] = function(self, name, sourceFn, destFn) -- ./signal/signal.can:60
if not self["signals"][name] then -- ./signal/signal.can:61
self["signals"][name] = {} -- ./signal/signal.can:62
end -- ./signal/signal.can:62
for i, fn in ipairs(self["signals"][name]) do -- ./signal/signal.can:64
if fn == sourceFn then -- ./signal/signal.can:65
self["signals"][name][i] = destFn -- ./signal/signal.can:66
break -- ./signal/signal.can:67
end -- ./signal/signal.can:67
end -- ./signal/signal.can:67
end, -- ./signal/signal.can:67
["clear"] = function(self) -- ./signal/signal.can:73
self["signals"] = {} -- ./signal/signal.can:74
end, -- ./signal/signal.can:74
["emit"] = function(self, name, ...) -- ./signal/signal.can:80
if self["signals"][name] then -- ./signal/signal.can:81
for _, fn in ipairs(self["signals"][name]) do -- ./signal/signal.can:82
fn(...) -- ./signal/signal.can:83
end -- ./signal/signal.can:83
end -- ./signal/signal.can:83
end -- ./signal/signal.can:83
} -- ./signal/signal.can:83
registry_mt["__index"] = registry_mt -- ./signal/signal.can:88
local signal -- ./signal/signal.can:96
signal = { -- ./signal/signal.can:96
["new"] = function() -- ./signal/signal.can:99
return setmetatable({ ["signals"] = {} }, registry_mt) -- ./signal/signal.can:100
end, -- ./signal/signal.can:100
["signals"] = {}, -- ./signal/signal.can:104
["bind"] = function(...) -- ./signal/signal.can:105
return registry_mt["bind"](signal, ...) -- ./signal/signal.can:106
end, -- ./signal/signal.can:106
["unbind"] = function(...) -- ./signal/signal.can:108
return registry_mt["unbind"](signal, ...) -- ./signal/signal.can:109
end, -- ./signal/signal.can:109
["unbindAll"] = function(...) -- ./signal/signal.can:111
return registry_mt["unbindAll"](signal, ...) -- ./signal/signal.can:112
end, -- ./signal/signal.can:112
["replace"] = function(...) -- ./signal/signal.can:114
return registry_mt["replace"](signal, ...) -- ./signal/signal.can:115
end, -- ./signal/signal.can:115
["clear"] = function(...) -- ./signal/signal.can:117
return registry_mt["clear"](signal, ...) -- ./signal/signal.can:118
end, -- ./signal/signal.can:118
["emit"] = function(...) -- ./signal/signal.can:120
return registry_mt["emit"](signal, ...) -- ./signal/signal.can:121
end, -- ./signal/signal.can:121
["event"] = nil, -- ./signal/signal.can:136
["registerEvents"] = function() -- ./signal/signal.can:141
local callbacks = { -- ./signal/signal.can:142
"displayrotated", -- ./signal/signal.can:143
"draw", -- ./signal/signal.can:143
"load", -- ./signal/signal.can:143
"lowmemory", -- ./signal/signal.can:143
"quit", -- ./signal/signal.can:143
"update", -- ./signal/signal.can:143
"directorydropped", -- ./signal/signal.can:144
"filedropped", -- ./signal/signal.can:144
"focus", -- ./signal/signal.can:144
"mousefocus", -- ./signal/signal.can:144
"resize", -- ./signal/signal.can:144
"visible", -- ./signal/signal.can:144
"keypressed", -- ./signal/signal.can:145
"keyreleased", -- ./signal/signal.can:145
"textedited", -- ./signal/signal.can:145
"textinput", -- ./signal/signal.can:145
"mousemoved", -- ./signal/signal.can:146
"mousepressed", -- ./signal/signal.can:146
"mousereleased", -- ./signal/signal.can:146
"wheelmoved", -- ./signal/signal.can:146
"gamepadaxis", -- ./signal/signal.can:147
"gamepadpressed", -- ./signal/signal.can:147
"gamepadreleased", -- ./signal/signal.can:147
"joystickadded", -- ./signal/signal.can:148
"joystickaxis", -- ./signal/signal.can:148
"joystickhat", -- ./signal/signal.can:148
"joystickpressed", -- ./signal/signal.can:148
"joystickreleased", -- ./signal/signal.can:148
"joystickremoved", -- ./signal/signal.can:148
"touchmoved", -- ./signal/signal.can:149
"touchpressed", -- ./signal/signal.can:149
"touchreleased" -- ./signal/signal.can:149
} -- ./signal/signal.can:149
local event = signal["event"] -- ./signal/signal.can:151
for _, callback in ipairs(callbacks) do -- ./signal/signal.can:152
if callback == "update" then -- ./signal/signal.can:153
if love[callback] then -- ./signal/signal.can:154
local old = love[callback] -- ./signal/signal.can:155
love[callback] = function(dt) -- ./signal/signal.can:156
old(dt) -- ./signal/signal.can:157
event:emit(callback, dt) -- ./signal/signal.can:158
end -- ./signal/signal.can:158
else -- ./signal/signal.can:158
love[callback] = function(dt) -- ./signal/signal.can:161
event:emit(callback, dt) -- ./signal/signal.can:162
end -- ./signal/signal.can:162
end -- ./signal/signal.can:162
else -- ./signal/signal.can:162
if love[callback] then -- ./signal/signal.can:166
local old = love[callback] -- ./signal/signal.can:167
love[callback] = function(...) -- ./signal/signal.can:168
old(...) -- ./signal/signal.can:169
event:emit(callback, ...) -- ./signal/signal.can:170
end -- ./signal/signal.can:170
else -- ./signal/signal.can:170
love[callback] = function(...) -- ./signal/signal.can:173
event:emit(callback, ...) -- ./signal/signal.can:174
end -- ./signal/signal.can:174
end -- ./signal/signal.can:174
end -- ./signal/signal.can:174
end -- ./signal/signal.can:174
end -- ./signal/signal.can:174
} -- ./signal/signal.can:174
signal["event"] = signal["new"]() -- ./signal/signal.can:182
return signal -- ./signal/signal.can:184
