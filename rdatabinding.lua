local binding = {}

function binding.bindable(init)
    local t = {}
    local mt
    mt = {
        bind____ = {},
        maxn____ = {}, -- no table.maxn in lua5.3

        __index = function(table, key)
            return mt[key]
        end,

        __newindex = function(table, key, value)
            local v_old = mt[key]
            if v_old == value then
                return
            end
            mt[key] = value
            local binds = mt.bind____[key]
            if binds then
            	local maxn = mt.maxn____[key]
            	for i = 1, maxn do
                	local v = binds[i]
                	if type(v) == "function" then
                    	v(value, v_old)
                    end
                end
            end
        end
    }
    setmetatable(t, mt)
    if type(init) == "table" then
	    for k, v in pairs(init) do
	        t[k] = v
	    end
    end
    return t
end

function binding.watch(table, key, func)
    local binds = table.bind____
    local maxns = table.maxn____
    if not binds[key] then
    	binds[key] = {}
    	maxns[key] = 0
    end
    local bind = binds[key]
    local tag = #bind + 1
    bind[tag] = func
    if tag > maxns[key] then
    	maxns[key] = tag
    end
    return tag
end

function binding.unwatch(table, key, tag)
	local binds = table.bind____
	if binds[key] then
		binds[key][tag] = nil
	end
end

function binding.watchonce(table, key, func)
	local tag
	local f = function(...)
		func(...)
		binding.unwatch(table, key, tag)
	end
	tag = binding.watch(table, key, f)
	return tag
end

function binding.bind(table_s, key_s, table_d, key_d, filter)
	return binding.watch(table_s, key_s, function(new, old)
		local value = new
		if type(filter) == "function" then
			value = filter(new, old)
		end
		table_d[key_d] = value
	end)
end

function binding.unbind(table_s, key_s, tag)
	return binding.unwatch(table_s, key_s, tag)
end

function binding.bindonce(table_s, key_s, table_d, key_d, filter)
	return binding.watchonce(table_s, key_s, function(new, old)
		local value = new
		if type(filter) == "function" then
			value = filter(new, old)
		end
		table_d[key_d] = value
	end)
end

function binding.bindtwoway(table_a, key_a, table_b, key_b, filter_a2b, filter_b2a)
	local tag1 = binding.bind(table_a, key_a, table_b, key_b, filter_a2b)
	local tag2 = binding.bind(table_b, key_b, table_a, key_a, filter_b2a)
	return tag1, tag2
end

return binding
