--- ctrµLua backend 0.0.1 for Ubiquitousse.
-- Provides a partial Ubiquitousse API. Still a lot to implement.
-- Made for some ctrµLua version and Ubiquitousse 0.0.1.
-- See `ubiquitousse` for Ubiquitousse API.

-- General
local version = "0.0.1"

-- Require stuff
local uqt = require((...):match("^(.-ubiquitousse)%."))
local ctr = require("ctr")
local gfx = require("ctr.gfx")

-- Version compatibility warning
do
	local function checkCompat(stuffName, expectedVersion, actualVersion)
		if actualVersion ~= expectedVersion then
			local txt = ("Ubiquitousse ctrµLua backend version "..version.." was made for %s %s but %s is used!\nThings may not work as expected.")
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
end

-- Redefine all functions in tbl which also are in toAdd, so when used they call the old function (in tbl) and then the new (in toAdd).
local function add(tbl, toAdd)
	for k,v in pairs(toAdd) do
		local old = tbl[k]
		tbl[k] = function(...)
			old(...)
			return v(...)
		end
	end
end

-- uqt
uqt.backend = "ctrulua"

-- uqt.event: TODO

-- uqt.draw: TODO

-- uqt.audio: TODO

-- uqt.time
if uqt.time then
add(uqt.time, {
	get = ctr.time
})
end

-- uqt.input: TODO
