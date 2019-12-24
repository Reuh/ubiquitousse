local uqt = require((...):match("^(.-ubiquitousse)%."))

local function checkCompat(stuffName, expectedVersion, actualVersion)
	if actualVersion ~= expectedVersion then
		local txt = ("Ubiquitousse Löve backend was made for %s %s but %s is used!\nThings may not work as expected.")
		            :format(stuffName, expectedVersion, actualVersion)
		print(txt)
	end
end
checkCompat("Löve", "11.3.0", ("%s.%s.%s"):format(love.getVersion()))
checkCompat("Ubiquitousse", "0.0.1", uqt.version)
