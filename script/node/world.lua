require "script/node/node"

World = Node{
    classType = "world",
    player = nil,
	
	currentMap = "World",
	playerX = 113,
	playerY = 105,
    actualPlayerX = 113,
    actualPlayerY = 105,
    
    movePlayer = function(self, x, y)
        self:add("actualPlayerX", x)
        self:add("actualPlayerY", y)
        self.playerX = math.floor(self.actualPlayerX)
        self.playerY = math.floor(self.actualPlayerY)
    end,
}