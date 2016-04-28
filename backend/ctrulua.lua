--- ctrµLua backend 0.0.1 for Abstract.
-- Provides a partial abstract API. Still a lot to implement.
-- Made for some ctrµLua version and abstract 0.0.1.
-- See `abstract` for Abstract API.

-- General
local version = "0.0.1"

-- Require stuff
local abstract = require((...):match("^(.-abstract)%."))
local ctr = require("ctr")
local gfx = require("ctr.gfx")

-- Version compatibility warning
do
	local function checkCompat(stuffName, expectedVersion, actualVersion)
		if actualVersion ~= expectedVersion then
			local txt = ("Abstract ctrµLua backend version "..version.." was made for %s %s but %s is used!\nThings may not work as expected.")
			            :format(stuffName, expectedVersion, actualVersion)
			print(txt)
			for i=0,300 do
				gfx.start(gfx.TOP)
					gfx.wrappedText(0, 0, txt, gfx.TOP_WIDTH)
				gfx.stop()
				gfx.render()
			end
		end
	end
	-- checkCompat("ctrµLua", "", ("%s.%s.%s"):format(love.getVersion())) -- not really a version, just get the latest build
	checkCompat("abstract", "0.0.1", abstract.version)
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

-- abstract
abstract.backend = "ctrulua"

-- abstract.event: TODO

-- abstract.draw: TODO

-- abstract.audio: TODO

-- abstract.time
if abstract.time then
add(abstract.time, {
	get = function()
		return ctr.time()
	end
})
end

-- abstract.input: TODO
