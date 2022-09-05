getmetatable("").__mod = function(a, b) -- Adds "%" string format operator to strings
    if not b then return a
    elseif type(b) == "table" then return string.format(a, unpack(b))
    else return string.format(a, b) end
end

function export(class) -- Exports table and metatable data to a table
    local t = {}
    local mt = getmetatable(class).__index
    updateTable(mt, class)
    
    for k, v in pairs(mt) do
        if type(v) == "table" then
            local nested = v
            if v[export] then nested = v:export() end
            
            t[k] = nested
        elseif type(v) ~= "function" then
            t[k] = v
        end
    end
    
    return t
end

function dumpTable(o) -- Dumps a table to a string
   if type(o) == 'table' then
      local s = '{ '
      for k, v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s..'['..k..'] = '..dumpTable(v).. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function dumpClass(c) -- Dumps a class to a string
    return dumpTable(c:export())
end

function updateTable(t1, t2) -- Updates t1 with t2's values
    for k, v in pairs(t2) do t1[k] = v end
end

function appendTable(t1, t2) -- Appends t2 to t1
    for k, v in pairs(t2) do table.insert(t1, v) end
end

function sliceTable(t, first, last, step) -- Slices a table with integer indices
    local first = first or 1
    local last = last or #t
    local step = step or 1
    
    local sliced = {}
    
    for i = first, last, step do
        table.insert(sliced, t[i])
    end
    
    return sliced
end 

function rand(...) -- Picks a random number between low and high
    local arg = {...}
    local a = 0
    local b = 1
    
    if #arg == 1 then
        a = arg[1][1]
        b = arg[1][2]
    else
        a = arg[1]
        b = arg[2]
    end
    
    if a > b then
        local buffer = a
        a = b
        b = buffer
    end
    
    return math.random(a, b)
end

function isInRange(str, low, high) -- Determines if a string is between a number range
    num = tonumber(str)
    if str:match("^%-?%d+$") and num >= low and num <= high then return true else return false end
end

function count(str, subString) -- Counts occurences of a string in a string
    return select(2, str:gsub(subString, ""))
end

function split(str, sep, num) -- Splits a string by a string and returns a table
    local sep = sep or " "
    local num = num or false
    local start = 1
    local t = {}
    
    while true do
        local first, last = string.find(str, sep, start, true)
        if not first then
            table.insert(t, string.sub(str, start))
            break
        end
        table.insert(t, string.sub(str, start, first - 1))
        start = last + 1
    end
    
    if num ~= false then
        local t1 = sliceTable(t, 1, num)
        table.insert(t1, table.concat(sliceTable(t, num + 1), sep))
        
        t = t1
    end
    
    return t
end

function inString(str, character)
    local t = {}
    str:gsub(".", function(c) t[c] = true end)
    
    if t[character] then return true end
    return false
end

function repr(str) -- Returns a string with escape codes backslashed
    return string.format("%q", str):gsub("\\\n", "\\n")
end

function deepcopy(orig) -- Recursively copies a table
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end