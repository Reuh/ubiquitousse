local uqt = require((...):match("^(.-ubiquitousse)%."))
local ctr = require("ctr")
local gfx = require("ctr.gfx")

local function checkCompat(stuffName, expectedVersion, actualVersion)
	if actualVersion ~= expectedVersion then
		local txt = ("Ubiquitousse ctrµLua backend was made for %s %s but %s is used!\nThings may not work as expected.")
		            :format(stuffName, expectedVersion, actualVersion)
		print(txt)
		for _=0,300 do
			gfx.start(gfx.TOP)
				gfx.wrappedText(0, 0, txt, gfx.TOP_WIDTH)
			gfx.stop()
			gfx.render()
		end
	end
end
checkCompat("ctrµLua", "v1.0", ctr.version) -- not really a version, just get the latest build
checkCompat("Ubiquitousse", "0.0.1", uqt.version)
