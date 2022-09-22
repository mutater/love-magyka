require "script/node/entity"
require "script/node/node"

Map = Node{
    classType = "map",
    name = "map",
    tiles = {},
    collision = {},
    groups = {},
    data = {},
    background = {0, 0, 0},
    
    get = function(self, key, ...)
        local arg = {...}
        
        if key == "tile" then
            local x = arg[1]
            local y = arg[2]
            
            if x >= #self.tiles[1] or x < 1 then return self.background end
            if y >= #self.tiles or y < 1 then return self.background end
            
            return self.tiles[y][x]
        elseif key == "collision" then
            local x = arg[1]
            local y = arg[2]
            
            if x >= #self.collision[1] or x < 1 then return false end
            if y >= #self.collision or y < 1 then return false end
            
            return self.collision[y][x]
        elseif key == "group" then
            local x = arg[1]
            local y = arg[2]
            
            if x >= #self.groups[1] or x < 0 then return 0 end
            if y >= #self.groups or y < 0 then return 0 end
            
            return self.groups[y][x]
        else
            return self[key]
        end
    end,
    
    draw = function(self, playerX, playerY, width, height, mapLeft, mapTop)
        if #self.tiles[1] < width then width = #self.tiles[0] end
        if #self.tiles < height then height = #self.tiles end
        
        local left = playerX - math.floor(width / 2) - 1
        local right = playerX + math.floor(width / 2)
        local top = playerY - math.floor(height / 2) - 1
        local bottom = playerY + math.floor(height / 2)
        
        local mapY = mapTop
        for y = top, bottom do
            for x = left, right do
                draw:setColor(self:get("tile", x, y))
                draw:rectangle("fill", mapLeft + draw:getFW() * (x - 1) * 2, mapTop + draw:getFH() * (y - 1), draw:getFW() * 2, draw:getFH())
            end
        end
    end,

    encounter = function(self, group)
        local enemies = self.data.encounters[group]
        enemies = {newEntity(enemies[rand(1, #enemies)])}
        return enemies
    end
}