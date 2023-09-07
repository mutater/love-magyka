require "script/tools"

function Node(class)
    for k, v in pairs(class) do
        if type(v) == "table" then class[k] = deepcopy(v) end
    end
    
    if not class.init then
        class.init = function(self) return nil end
    end
    if not class.get then
        class.get = function(self, key)
            if self[key] then return self[key] else return nil end
        end
    end
    if not class.set then
        class.set = function(self, key, value) self[key] = value end
    end
    if not class.add then
        class.add = function(self, key, value) self:set(key, self:get(key) + value) end
    end
    if not class.multiply then
        class.multiply = function(self, key, value, round)
            value = self:get(key) * value
            if round == "ceil" then self:set(key, math.ceil(value))
            elseif round == "floor" then self:set(key, math.floor(value))
            else self:set(key, value) end
        end
    end
    if not class.divide then
       class.divide = function(self, key, value, round)
            value = self:get(key) / value
            if round == "ceil" then self:set(key, math.ceil(value))
            elseif round == "floor" then self:set(key, math.floor(value))
            else self:set(key, value) end
        end
    end
    if not class.export then
        class.export = function(self) return export(self) end
    end
    
    return setmetatable(class, {
        __call = function(self, init)
            return setmetatable(init or {}, {__index = class})
        end
    })
end