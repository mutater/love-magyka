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
    
    draw = function(self, playerX, playerY, screenWidth, screenHeight)
        widthTiles = 39
        heightTiles = 39
        
        if #self.tiles[1] < widthTiles then widthTiles = #self.tiles[1] end
        if #self.tiles < heightTiles then heightTiles = #self.tiles end
        
        tileWidth = math.floor((screenHeight - 60) / widthTiles)
        tileHeight = math.floor((screenHeight - 60) / heightTiles)
        tileSize = math.max(tileWidth, tileHeight)
        
        local height = tileHeight * heightTiles
        local width = tileWidth * widthTiles
        
        local mapTop = math.floor((screenHeight - height) / 2)
        local mapLeft = screenWidth - width - mapTop
        
        local left = playerX - math.floor(widthTiles / 2)
        local right = playerX + math.floor(widthTiles / 2)
        local top = playerY - math.floor(heightTiles / 2)
        local bottom = playerY + math.floor(heightTiles / 2)
        
        draw.autoSpace = false
        for y = top, bottom do
            for x = left, right do
                if x == playerX and y == playerY then draw:setColor("black")
                else draw:setColor(self:get("tile", x, y)) end
                
                local tileX = mapLeft + tileSize * (x - left)
                local tileY = mapTop + tileSize * (y - top)
                draw:rectangle("fill", tileX, tileY, tileSize, tileSize)
                
                if x == playerX and y == playerY then
                    draw:setColor("white")
                    draw:setLine(2)
                    draw:rectangle("line", tileX + 1, tileY + 1, tileSize - 2, tileSize - 2)
                    draw:setLine(1)
                end
            end
        end
        draw.autoSpace = true
    end,

    encounter = function(self, group)
        local enemies = self.data.encounters[group]
        enemies = {newEntity(enemies[rand(1, #enemies)])}
        return enemies
    end
}