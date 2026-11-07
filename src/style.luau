-- make a style from another one: style.extend(base, { surface = { corner = UDim.new(0.1, 0) } })
-- tables merge key by key, lists (gradient colors) and roblox values (Color3, Font, UDim) are replaced

local style = {}

local function is_list(value)
	return type(value) == "table" and #value > 0
end

local function copy(value)
	if type(value) ~= "table" then return value end
	local out = {}
	for key, item in value do out[key] = copy(item) end
	return out
end

function style.extend(base, overrides)
	local out = copy(base)
	for key, value in overrides do
		if type(value) == "table" and type(out[key]) == "table" and not is_list(value) then
			out[key] = style.extend(out[key], value)
		else
			out[key] = copy(value)
		end
	end
	return out
end

return style
