-- ubiquitousse.util

--- Various functions useful for game developement.
-- No dependicy on either ubiquitousse or a ubiquitousse backend.
local util
util = {
	--- AABB collision check.
	-- @tparam number x1 first rectangle top-left x coordinate
	-- @tparam number y1 first rectangle top-left y coordinate
	-- @tparam number w1 first rectangle width
	-- @tparam number h1 first rectangle height
	-- @tparam number x2 second rectangle top-left x coordinate
	-- @tparam number y2 second rectangle top-left y coordinate
	-- @tparam number w2 second rectangle width
	-- @tparam number h2 second rectangle height
	-- @treturn true if the objects collide, false otherwise
	aabb = function(x1, y1, w1, h1, x2, y2, w2, h2)
		if w1 < 0 then x1 = x1 + w1; w1 = -w1 end
		if h1 < 0 then y1 = y1 + h1; h1 = -h1 end
		if w2 < 0 then x2 = x2 + w2; w2 = -w2 end
		if h2 < 0 then y2 = y2 + h2; h2 = -h2 end
		return x1 + w1 >= x2 and x1 <= x2 + w2 and
		       y1 + h1 >= y2 and y1 <= y2 + h2
	end,

	--- Remove the first occurence of an element in a table.
	-- @tparam table t the table
	-- @param x the element to remove
	-- @return x
	remove = function(t, x)
		for i, v in ipairs(t) do
			if v == x then
				table.remove(t, i)
				break
			end
		end
		return x
	end,

	--- Returns a new table where the keys and values have been inverted.
	-- @tparam table t the table
	-- @treturn table the inverted table
	invert = function(t)
		local r = {}
		for k, v in pairs(t) do
			r[v] = k
		end
		return r
	end
}

return util
