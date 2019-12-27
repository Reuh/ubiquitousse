local uqt = require((...):match("^(.-ubiquitousse)%."))

local madeForLove = { 11, "x", "x" }
local madeForUqt = "0.0.1"

-- Check versions
local txt = ""

local actualLove = { love.getVersion() }
for i, v in ipairs(madeForLove) do
	if v ~= "x" then
		if actualLove[i] ~= v then
			txt = txt .. ("Ubiquitousse Löve backend was made for LÖVE %s.%s.%s but %s.%s.%s is used!\n")
				:format(madeForLove[1], madeForLove[2], madeForLove[3], actualLove[1], actualLove[2], actualLove[3])
			break
		end
	end
end

if uqt.version ~= madeForUqt then
	txt = txt .. ("Ubiquitousse Löve backend was made for Ubiquitousse %s but %s is used!\n")
		:format(madeForUqt, uqt.version)
end

-- Show warnings
if txt ~= "" then
	txt = txt .. "Things may not work as expected.\n"
	print(txt)
	love.window.showMessageBox("Compatibility warning", txt, "warning")
end
