local widget = {}

return setmetatable(widget, {
	__index = function(table, key)
		local module = rawget(table, key)
		return module or require("feign.widget." .. key)
	end
})
