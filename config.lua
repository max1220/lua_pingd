return {
	log = {
		-- Enable/disable logging levels
		debug = false,
		notice = true,
		error = true
	},
	hosts = {
		-- Format is: ["name"] = "host"
		["Google DNS"] = "8.8.8.8",
		["Localhost"] = "127.0.0.1",
		["Modem"] = "192.168.100.1",
		["Router"] = "192.168.1.1",
	},
	backlog = 1000, --maximum ammount of values held in memory
	jsons = {
		enabled = true, -- write JSONs? If you disable this the SVG graphs aren't restart proof.
		persistence = false, -- Load old JSONs on startup?
		update = 5, --update interval in seconds
		output_format = "jsons/{{name}}.json" -- Where to save the JSONs to. Supported: {{name}}, {{host}}
	},
	graphs = {
		enabled = true, -- generate SVG graphs?
		output_format = "graphs/{{name}}.svg",  -- Where to save the graphs. Supported: {{name}}, {{host}}
		width = 800, -- Width of the graph in pixels
		height = 400, -- Height of the graph in pixels
		update = 5 -- update interval in seconds
	},
	html = {
		enabled = true, -- Also render HTML on startup?
		dynamic = true, -- Update HTML during runtime?
		update = 5, -- update interval in seconds
		output_file = "html/index.html", -- Where to save the generated file
		template = "html/template.html.lua", -- template to use for generating the file
		page_title = "lua_pingd" -- Title of the page
	}
}
