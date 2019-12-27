local uqt = require((...):match("^(.-ubiquitousse)%."))
local ctr = require("ctr")
local gfx = require("ctr.gfx")

local madeForCtr = "v1.0"
local madeForUqt = "0.0.1"

-- Check versions
local txt = ""

if ctr.version ~= madeForCtr then
	txt = txt .. ("Ubiquitousse ctrµLua backend was made for ctrµLua %s but %s is used!\n")
		:format(madeForCtr, uqt.version)
end

if uqt.version ~= madeForUqt then
	txt = txt .. ("Ubiquitousse ctrµLua backend was made for Ubiquitousse %s but %s is used!\n")
		:format(madeForUqt, uqt.version)
end

-- Show warnings
if txt ~= "" then
	txt = txt .. "Things may not work as expected.\n"
	print(txt)
	for _=0,300 do
		gfx.start(gfx.TOP)
			gfx.wrappedText(0, 0, txt, gfx.TOP_WIDTH)
		gfx.stop()
		gfx.render()
	end
end
