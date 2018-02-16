local insert = table.insert
local concat = table.concat

local function elem_t(name, parms, elems, parms_list)
	local elem_t = {
		name = name,
		parms = parms,
		elems = elems,
		parms_list = parms_list
	}
	local elem_mt = {
		__tostring = function(t)
			local args = t._args or {}
			local ret = {"<", t.name}
			if t.parms then
				local parms_str = {}
				if t.parm_list then
					for _,parm in ipairs(t.parms) do
						insert(parms_str, parm.k.."=".."\""..parm.v.."\"")
					end
				else
					for k,v in pairs(t.parms) do
						insert(parms_str, k.."=".."\""..v.."\"")
					end
				end			
				if #parms_str >= 1 then
					insert(ret, " ")
					insert(ret, table.concat(parms_str, " "))
				end
			end
			if not t.elems then
				insert(ret, " /")
			end
			insert(ret, ">")
			if t.elems then
				for _,elem in pairs(t.elems) do
					if type(elem) == "function" then
						insert(ret, tostring(elem(args) or ""))
					else
						elem._args = args
						insert(ret, tostring(elem or ""))
						elem._args = nil
					end
				end
				insert(ret,"</"..t.name..">")
			end				
			return concat(ret)
		end,
		newindex = function(t,k,v) end -- TODO: insert elements/text or modify parameters based on type of k
	}
	setmetatable(elem_t, elem_mt)
	return elem_t
end

local function generate(tree, args)
	local ret = {}
	local args = args or {}
	for _, elem in pairs(tree) do
		if type(elem) == "function" then
			insert(ret, tostring(elem(args) or ""))
		else
			elem._args = args
			insert(ret, tostring(elem or ""))
			elem._args = nil
		end
	end
	return concat(ret)
end

local function text(str)
	local text_t = { text = str}
	local text_mt = {
		__tostring = function(t)
			return tostring(t.text)
		end
	}
	setmetatable(text_t, text_mt)
	return text_t
end

local function variable(name, default)
	return function(args)
		if args and type(args) == "table" then
			return args[name] or default
		else
			return default
		end
	end
end

local function test(t)
	local text = t.text
	local elem = t.element
	local var = t.variable

	local tree = {
		text("<!DOCTYPE html>"),
		elem("html", {}, {
			elem("body", {style="background-color: grey; color: #333; font-family: sans-serif; padding: 0 0; margin: 0 0;"}, {
				elem("div", {style="background-color: white; max-width: 800px; margin: 0 auto;"}, {
					elem("h1", {}, {
						text("Hello World!")
					}),
					elem("p", {}, {
						text("Current date: "),
						var("date", "No date aviable")
					}),
					function(args)
						if args.secret then
							return elem("p", {}, {text("I'm secret!")})
						end
					end
				})
			})
		})
	}
	
	table.insert(tree, function()
		print("Running custom funtion!")
		return "<!-- Comment from custom function! -->"
	end)
	
	print("Stylesheet of body: (Should be: background-color: grey; color: #333; font-family: sans-serif; padding: 0 0; margin: 0 0;)")
	print(tree[2].elems[1].parms.style)
	print()
	print("Body as string:")
	print(tree[2].elems[1])
	print()
	print("Generating full tree as string without date")
	print(generate(tree))
	print("Generating full tree as string with date")
	print(generate(tree, {date = os.date()}))
	print("Generating full tree as string with date and secret")
	print(generate(tree, {date = os.date(), secret = true}))
	
end

return {
	generate = generate,
	element = elem_t,
	variable = variable,
	text = text,
	_test = test,
}
