getmetatable("").__mod = function(a, b) -- Adds "%" string format operator to strings
    if not b then return a
    elseif type(b) == "table" then return string.format(a, unpack(b))
    else return string.format(a, b) end
end


-- Class & Table

function export(class) -- Exports table and metatable data to a table
    local t = {}
    local mt = getmetatable(class).__index
    updateTable(mt, class)
    
    for k, v in pairs(mt) do
		if not startsWith(k, "linked") then
			if type(v) == "table" then
				local nested = v
				if v["export"] then nested = v:export() end
				
				t[k] = nested
			elseif type(v) ~= "function" then
				t[k] = v
			end
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
	if hasKey(c) then return dumpTable(c:export())
	else return dumpTable(c) end
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

function isInTable(t, item) -- Checks if item is in table
	for k, v in pairs(t) do
		if item == v then return true end
	end
	return false
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

function has(t, val) -- Checks if table contains value
    for k, v in pairs(t) do
        if v == val then return true end
    end
    return false
end

function hasKey(t, key) -- Checks if table contains key
	if t == nil then return false end
	if type(t) ~= "table" then return false end
	return not not t[key]
end

function hasFunction(t, func) -- Checks if table contains function
	if type(t) ~= "table" then return false end
	return type(t[func]) == "function"
end

function getKeys(t) -- Returns a table of a table's keys
	local keys = {}
	
	for k, _ in pairs(t) do
		table.insert(keys, k)
	end
	
	return keys
end

function isEmpty(t) -- Returns true if table exists and is empty
	if t == nil then return false end
	for _, _ in pairs(t) do return false end
	return true
end

function isNotEmpty(t) -- Returns true if table exists and is not empty
	if t == nil then return false end
	return not isEmpty(t)
end

-- Number

function rand(...) -- Picks a random number between low and high
    local arg = {...}
    local a = 0
    local b = 1
    
    if #arg == 1 then
        if type(arg) == "table" then
            a = arg[1][1]
            b = arg[1][2]
        else
            return arg[1]
        end
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

function clamp(val, min, max) -- Clamps a value between a minimum and maximum
	if val < min then return min
	elseif val > max then return max
	else return val end
end


-- String

function parseText(text) -- Returns a table of {parsedText, parsedColors, parsedIcons} and the length of the parsed text
	local text = text
	local oText = text
	local r, g, b, a = love.graphics.getColor()
	local c = {r, g, b}
	
	local parsedText = {}
	local parsedTextLength = 0
	local parsedColors = {}
	local parsedIcons = {}
	
	if text == nil then text = "" end
	
	if text[1] ~= "{" then text = "{ }"..text end
	
	while count(text, "{") > 0 do
		local i = text:find("{", 1, true)
		local j = text:find("}", 1, true)
		
		local colorName = text:sub(i + 1, j - 1)
		if color[colorName] then table.insert(parsedColors, color[colorName])
		else table.insert(parsedColors, c) end
		text = text:sub(j + 1)
		
		if count(text, "{") > 0 then bufferText = text:sub(1, text:find("{", 1, true) - 1)
		else bufferText = text end
		
		while count(bufferText, "<") > 0 do  -- Parse icons
			local k = bufferText:find("<", 1, true)
			local l = bufferText:find(">", 1, true)
			
			parsedIcons[k + parsedTextLength] = "icon/"..bufferText:sub(k + 1, l - 1)
			bufferText = bufferText:gsub(bufferText:sub(k, l), " ")
		end
		
		parsedTextLength = parsedTextLength + #bufferText
		table.insert(parsedText, bufferText)
		text = text:sub(#bufferText)
	end
	
	if #parsedText ~= #parsedColors then
		parsedText = {oText}
		text = oText
		parsedColors = {color.white}
	end
	
	return {parsedText, parsedColors, parsedIcons}, parsedTextLength
end

function strLen(str) -- Gets the length of a parsed string
	local _, length = parseText(str)
	return length
end

function cleanText(text) -- Cleans colors and icons from text
	if text then
		local parse, _ = parseText(text)
		return table.concat(parse[1], "")
	end
end

function startsWith(str, start) -- Checks if string starts with "start"
	local str = cleanText(str)
    return string.sub(str, 1, strLen(start)) == start
end

function isInRange(str, low, high) -- Determines if a string is between a number range
    num = tonumber(str)
    if str:match("^%-?%d+$") and num >= low and num <= high then return true else return false end
end

function toTable(str) -- Converts a string to a table
	if str == "" then return {} end
	local t = {}
	str:gsub(".", function(c) table.insert(t,c) end)
	return t
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

function inString(str, character) -- Returns the index of the first character found in string
    local t = toTable(str)
	
	for i = 1, #t do
		if t[i] == character then return i end
	end
	
	return false
end

function repr(str) -- Returns a string with escape codes backslashed
    return string.format("%q", str):gsub("\\\n", "\\n")
end

function removeStartEnd(str, startChar, endChar) -- Removes all characters from startChar to endChar
	local t = {str}
	local startIndex = inString(t[1], startChar)
	local endIndex = inString(t[1], endChar)
	local i = 1
	
	while startIndex and endIndex do
		local ti = t[i]
		if i == 1 then
			t = split(ti, str:sub(startIndex, endIndex), 1)
		else
			t = sliceTable(t, 1, i - 1)
			appendTable(t, split(ti, str:sub(startIndex, endIndex), 1))
		end
		
		startIndex = inString(ti, startChar)
		endIndex = inString(ti, endChar)
		i = i + 1
	end
	
	return table.concat(t, "")
end

function rjust(str, length, c) -- Adds characters (space by default) to the beginning of a string until the string length is correct
	local c = c or " "
	return string.rep(c, length - strLen(str))..str
end

function ljust(str, length, c) -- Adds characters (space by default) to the end of a string until the string length is correct
	local c = c or " "
	return str..string.rep(c, length - strLen(str))
end

function cjust(str, length, c) -- Adds characters (space by default) to the end and beginning of a string until the string length is correct
	local c = c or " "
	local padding = length - strLen(str)
	local left = math.ceil(padding / 2)
	local right = math.floor(padding / 2)
	return string.rep(c, left)..str..string.rep(c, right)
end

function title(str) -- Capitalizes the first letter of every word in a string. Can take a table and capitalize every string in the table.
    if type(str) == "string" then
        function titleCase(first, rest)
            return first:upper()..rest:lower()
        end
        
        local str, _ = string.gsub(str, "(%a)([%w_']*)", titleCase)
        
        return str
    elseif type(str) == "table" then
        local t = {}
        
        for k, v in ipairs(str) do
            t[k] = title(v)
        end
        
        return t
    else
        return str
    end
end

function concat(str1, str2) -- Concats two strings, handling nil values
    if str1 == nil and str2 == nil then return ""
    elseif str1 == nil then return str2
    elseif str2 == nil then return str1
    else return str1..str2 end
end

function lowerFirst(str) -- Sets the first character of a string to lowercase
	return string.lower(string.sub(str, 1, 1))..string.sub(str, 2)
end


-- Boolean

function tert(condition, ifTrue, ifFalse) -- Returns ifTrue if true and ifFalse if false
    if condition == true then return ifTrue
    else return ifFalse end
end

function ifNil(value, ifNil) -- Returns ifNil if value is nil
    if value == nil then return ifNil else return value end
end


-- Database

function getNamesFromDatabase(t) -- Gets all names from a database
	local names = {}
	local query = db:prepare("select * from %s" % {t})
	for row in query:nrows() do
		if row.name then table.insert(names, row.name) end
	end
	return names
end


-- Etc

function printClass(t)
	print(dumpClass(t))
end

function printxy(x, y)
	print("%d, %d" % {x, y})
end

function pointInRect(px, py, rx, ry, rw, rh) -- Determins if a point is inside of a rectangle
    if px < rx or px > rx + rw then return false end
    if py < ry or py > ry + rh then return false end
    return true
end