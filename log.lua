--[[
log.lua - simple pure-lua logging functions

This library aims to provide a simple logging function in pure.
It supports output to multiple streams, making seperate log files easy.

Licensed unter the MIT license.

For deatils see: https://github.com/max1220/lua-log/
]]



local function log(enabled, class, streams, color)
	local function _log(stream)
		return function(...)
			local _s = {}
			for _, str in ipairs({...}) do
				table.insert(_s, tostring(str))
			end
			local s = table.concat(_s, "\t")
			if color then
				stream:write(string.char(27), "[" .. color .. "m")
			end
			stream:write("["..os.date().."]["..class.."]\t"..s.."\n")
			if color then
				stream:write(string.char(27), "[0m")
			end
		end
	end
	if enabled then
		if type(streams) == "table" then
			local logs = {}
			for _,stream in pairs(streams) do
				table.insert(logs, _log(stream))
			end
			return function(...)
				for _,log_f in ipairs(logs) do
					log_f(...)
				end
			end
		else
			return _log(steams or io.stdout)
		end
	else
		return function() end
	end
end

return log
