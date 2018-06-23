#!/usr/bin/env lua
local json = require("cjson")
local config = require("config")
local log = require("log")
local time = require("time")
local xml = require("xml_generate")
local template = dofile(config.html.template)
local _debug = debug
local debug =  log(config.log.debug, "Debug",nil,32)
local notice = log(config.log.notice, "Notice")
local err = log(config.log.error, "Error",io.stderr,31)
local time = time.realtime
local elem = xml.element
local text = xml.text
local var = xml.variable

notice("Starting")

local hosts = {}
for name,host in pairs(config.hosts) do
	debug("PREPARING HOST ", host)
	local p = io.popen("ping -n -D -A " .. host)
	local host = {
		name = name,
		host = host,
		last_seq = 1,
		proc = p,
		data = {}
	}
	if config.jsons.persistence then
		notice("Loading previous data from JSONs")
		local input_file = config.jsons.output_format:gsub("{{name}}", host.name):gsub("{{host}}", host.host)
		local f = io.open(input_file, "r")
		if f then
			local data = f:read("*a")
			f:close()
			local obj = json.decode(data)
			host.data = obj.data
		else
			notice("Warning: Can't open JSON for reading: ", input_file,"(Ignoring)")
		end
	end
	table.insert(hosts, host)
end

local last_jsons = time()
local last_graphs = time()
local last_html = time()


function handle_line(line, host)
	debug("HANDLE_LINE", line, host.name)
	local seq, rtt = line:match("^%[.-] %d+ bytes from .-: icmp_seq=(%d+) ttl=%d+ time=(.-) ms")
	if seq and rtt then
		debug("REPLY", recv_time, seq, rtt)
		if host.last_seq + 1 < tonumber(seq) then
			debug("DROP", seq - host.last_seq - 1)
			table.insert(host.data, {
				type = "drop",
				ammount = seq - host.last_seq,
				time = time()
			})
		end
		table.insert(host.data, {
			type = "reply",
			time = time(),
			rtt = rtt,
			seq = seq
		})
		host.last_seq = seq
	else
		table.insert(host.data, {
			type = "error",
			line = line,
			time = time(),
			seq = seq
		})
	end
	while #host.data > config.backlog do
		table.remove(host.data, 1)
	end
end

function update_graphs()
	notice("Updating graphs")
	for _,host in pairs(hosts) do
		debug("UPDATING GRAPH", host.name)
		
		local extra_x = 80
		local extra_y = 20
		local graph_w = config.graphs.width - extra_x
		local graph_h = config.graphs.height - extra_y
		
		local svg = {
			text([[<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">]]),
			elem("svg", {
				["xmlns:xlink"] = "http://www.w3.org/1999/xlink",
				["xmlns"] = "http://www.w3.org/2000/svg",
				["xmlns:svg"] = "http://www.w3.org/2000/svg",
				["version"] = "1.1",
				["baseProfile"] = "full",
				["font-family"] = "Helvetica, Arial",
				["width"] = config.graphs.width,
				["height"] = config.graphs.height,
				-- ["viewBox"] = "0 0 " .. config.graphs.width+extra_x .. " " .. config.graphs.height + extra_y
			}, {
				elem("rect", {x=0, y=0, width=graph_w, height=graph_h, ["stroke-width"] = 1, fill="black"}),
				elem("g", {}, {}),
				elem("g", {}, {}),
				elem("rect", {x=graph_w, y=0, width=extra_x, height=graph_h+1, ["stroke-width"] = 1, fill="#111"}),
				elem("rect", {x=graph_w, y=0, width=1, height=graph_h, ["stroke-width"] = 1, fill="grey"}),
				elem("rect", {x=0, y=graph_h, width=graph_w + extra_x, height=extra_y, ["stroke-width"] = 1, fill="#111"}),
				elem("rect", {x=0, y=graph_h, width=graph_w, height=1, ["stroke-width"] = 1, fill="grey"})
			}),
		}
		
		local points = {}
		for _,data in ipairs(host.data) do
			if data.type == "reply" then
				-- table.insert(points, elem("circle", {cx = time() - data.time, cy = seq, r = 4, fill="#FFFFFF", stroke="#00FF00", ["stroke-width"]=2}))
				table.insert(points, {cx = time() - data.time, cy = data.rtt, r = 1, fill="#00FF00"})
			elseif data.type == "drop" then
				table.insert(points, {cx = time() - data.time, cy = 0, r = ammount, fill="#FFFF00"})
			elseif data.type == "error" then
				table.insert(points, {cx = time() - data.time, cy = 0, r = 0.5, fill="#FF0000"})
			end
		end
		local x_max = 0
		local y_max = 0
		for _,point_conf in pairs(points) do
			x_max = math.max(point_conf.cx, x_max)
			y_max = math.max(point_conf.cy, y_max)
		end
		local point_cords = {}
		for _,point_conf in pairs(points) do
			point_conf.cx = -(point_conf.cx/x_max) * graph_w + graph_w
			point_conf.cy = -(point_conf.cy/y_max) * graph_h + graph_h
			table.insert(point_cords, point_conf.cx..","..point_conf.cy)
			table.insert(svg[2].elems[3].elems, elem("circle", point_conf))
		end
		table.insert(svg[2].elems[2].elems, elem("polyline", {points = table.concat(point_cords, " "), fill="none", stroke="#333"}))
		
		
		local vdivs = math.floor(graph_h / 35)
		for i=0, vdivs-1 do
			local s = i/(vdivs-1)
			local cy = s*graph_h
			local text_e = elem("text", {x=graph_w+4, y=math.min(math.max(cy+4, 15), graph_h), fill="#AAA"}, {text(("%.3fms"):format((1-s)*y_max))})
			local line = elem("line", {x1=0,y1=cy,x2=graph_w,y2=cy, stroke="grey", ["stroke-width"] = 0.5})
			table.insert(svg[2].elems, text_e)
			table.insert(svg[2].elems, line)
		end
		
		
		local hdivs = math.floor(graph_w / 50)
		for i=0, hdivs-1 do
			local s = i/(hdivs-1)
			local cx = s*graph_w
			local text_e = elem("text", {x=math.max(cx-10,3), y=graph_h+15, fill="#AAA"}, {text(("%ds"):format((1-s)*x_max))})
			local line = elem("line", {x1=cx,y1=0,x2=cx,y2=graph_h, stroke="grey", ["stroke-width"] = 0.5})
			table.insert(svg[2].elems, text_e)
			table.insert(svg[2].elems, line)
		end
		
		
		
		local output_file = config.graphs.output_format:gsub("{{name}}", host.name):gsub("{{host}}", host.host)
		local f = io.open(output_file, "w")
		f:write(xml.generate(svg))
		f:close()
	end
end

function update_jsons()
	notice("Updating JSONs")
	for _,host in pairs(hosts) do
		debug("UPDATING JSON", host.name)
		local output_file = config.jsons.output_format:gsub("{{name}}", host.name):gsub("{{host}}", host.host)
		local f = io.open(output_file, "w")
		f:write(json.encode({
			host = host.host,
			name = host.name,
			data = host.data
		}))
		f:close()
	end
end

function update_html()
	notice("Updating HTML")
	local f = io.open(config.html.output_file, "w")
	
	local stats = {}
	for _, host in ipairs(hosts) do
		local sum = 0
		local min = math.huge
		local max = 0
		local replys = 0
		local drops = 0
		local errors = 0
		local last_seq = host.last_seq
		for _, value in ipairs(host.data) do
			if value.type == "drop" then
				drops = drops + value.ammount
			elseif value.type == "reply" then
				replys = replys + 1
				min = math.min(value.rtt, min)
				max = math.max(value.rtt, max)
				sum = sum + value.rtt
			elseif value.type == "error" then
				errors = errors + 1
			end
		end
		local total = replys + drops + errors
		local avg = sum / replys
		local stat_str = ([[min: %.4f, avg: %.4f, max: %.4f
replys: %d, drops: %d, errors: %d
total: %d, last seq: %d
]])
		stats[host] = stat_str:format(min, avg, max, replys, drops, errors, total, last_seq)
	end
	
	f:write(template({
		date = os.date(),
		hosts = hosts,
		stats = stats,
		config = config,
		dynamic = config.html.dynamic,
		page_title = config.html.page_title
	}))
	f:close()
end

if config.html.enabled then
	update_html()
	if config.jsons.persistence then
		update_graphs()
	end
end
notice("Startup complete!")

while true do
	debug("LOOP")
	for _, host in pairs(hosts) do	
		local line = host.proc:read("*l")
		handle_line(line, host)
	end
	if time() - last_jsons > config.jsons.update then
		update_jsons()
		last_jsons = time()
	end
	if time() - last_graphs > config.graphs.update then
		update_graphs()
		last_graphs = time()
	end
	if time() - last_html > config.html.update then
		update_html()
		last_html = time()
	end
end
