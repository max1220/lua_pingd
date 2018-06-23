local xml = require("xml_generate")

local text = xml.text
local elem = xml.element
local var = xml.variable

local tree = {
	text("<!DOCTYPE html>"),
	elem("html", {}, {
		elem("head", {}, {
			elem("title", {}, {var("page_title")}),
			elem("meta", {["http-equiv"] = "refresh", content="5; URL="}),
			elem("meta", {charset="utf-8"})
		}),
		elem("body", {style="background-color: #111; color: #333; font-family: sans-serif; "}, {
			elem("div", {style="background-color: #E9E9E9; max-width: 800px; margin: 0 auto; padding: 15px 20px; border-radius: 5px;"}, {
				elem("h1", {}, {
					var("page_title")
				}),
				elem("p", {style="font-weight: bold;"}, {text("Global stats")}),
				elem("pre", {}, {
					var("global_stats")
				}),
				elem("hr")
			}),
		})
	})
}

table.insert(tree[2].elems[2].elems[1].elems, function(args)
	local ret = {}
	for i,host in ipairs(args.hosts) do
		local graph_path = "../" ..args.config.graphs.output_format:gsub("{{name}}", host.name):gsub("{{host}}", host.host)
		local div = elem("div", {}, {
			elem("h2", {}, {text("Statistics for " .. host.name .. " (" .. host.host..")")}),
			elem("pre", {}, {text(args.stats[host] or "Statistics unaviable for this host")}),
			elem("img", {src=graph_path, style="border-radius: 6px;", alt="X Axis: time, Y Axis: RTT"}),
			elem("br")
		})
		table.insert(ret, tostring(div))
	end
	return table.concat(ret)
end)


return function(parms)
	parms.global_stats = parms.global_stats or "Global statistics currently unaviable"
	parms.page_title = parms.page_title or "lua_pingd"
	return xml.generate(tree, parms)
end
