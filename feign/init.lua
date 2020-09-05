local return_table = {}

return setmetatable(return_table, {
	__index = function(table, key)
		local module = rawget(table, key)
		return module or require("feign." .. key)
	end
})
