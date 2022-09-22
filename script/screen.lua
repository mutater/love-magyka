require "script/globals"
require "script/input"
require "script/tools"
require "script/generator"

require "library/TSerial"

screen = {
    
    -- Variables
    
    width = love.graphics.getWidth(),
    height = love.graphics.getHeight(),
    
    current = "title",
    post = "title",
    branch = {},
    branchData = {},
    branchDataDefaults = {
        newGame = {name="", stage="name", class=nil},
        continue = {saves=nil},
        map = {map=nil, portal=nil, hunting=false, steps=0},
        town = {town=nil},
        store = {items=nil, storeType=""},
        battle = {
            turn = 1,
            turnOrder = {},
            stage = "prebattle",
            enemy = {},
            text = {},
            art = nil,
            artChosen = false,
            item = nil,
			itemChosen = false,
            targetType = "",
			target = "",
        },
		inventoryBattle = {item=nil},
        artsBattle = {art=nil},
        victory = {stage="input", lootEntity=newEntity{}},
        defeat = {stage="curse"},
        inspectItem = {stage="input", quantity=1, item=nil, text={}},
        inspectItemBattle = {item=nil},
        inspectItemSell = {stage="input", quantity=1, item=nil},
        inspectItemStore = {stage="input", quantity=0, item=nil},
        inspectItemEquipped = {stage="input", item=nil, text=""},
        inspectArt = {stage="input", art=nil, text={}},
        inspectArtBattle = {art=nil},
        crafting = {station="none"},
        craftItem = {stage="input", recipe=nil, quantity=0},
    },
    key = "",
    
    -- Functionality Functions
    
    update = function(self, dt) -- Executes current screen
        self[self.current](self)
        self.key = ""
    end,
    
    up = function(self, args) -- Goes up a screen
        args = args or {}
        self.branchData[self.current] = nil
        self.current = self.branch[#self.branch]
        updateTable(self.branchData[self.current], args)
        table.remove(self.branch)
    end,
    
    upPast = function(self, name, args) -- Goes up one screen past a target screen
        local nextScreen = ""
        args = args or {}
        
        for i = #self.branch, 1, -1 do
            nextScreen = self.branch[i]
            table.remove(self.branchData, i)
            table.remove(self.branch, i)
            if name == nextScreen then
                nextScreen = self.branch[i - 1]
                table.remove(self.branch, i - 1)
                break
            end
        end
        
        self.current = nextScreen
        updateTable(self.branchData[self.current], args)
    end,
    
    down = function(self, name, args) -- Goes down a screen
        if name == "map" then
            self.branch = {}
            self.branchData = {}
        end
        
        args = args or {}
        self.branchData[name] = deepcopy(self.branchDataDefaults[name])
        updateTable(self.branchData[name], args)
        table.insert(self.branch, self.current)
        self.current = name
    end,
    
    get = function(self, key, screen) -- Gets a value from the current screen's branchData
		screen = screen or self.current
        if self.branchData[screen] == nil then return nil end
        return self.branchData[screen][key]
    end,
    
    set = function(self, key, value, screen) -- Sets a value to the current screen's branchData
		screen = screen or self.current
        if self.branchData[screen] == nil then self.branchData[screen] = {} end
        self.branchData[screen][key] = value
    end,
    
    add = function(self, key, value) -- Adds to a value from the current screen's branchData
        local data = self.branchData[self.current]
        
        if type(data[key]) == "string" then data[key] = data[key]..value
        else data[key] = data[key] + value end
    end,
    
    
    -- Abstraction Functions
    
    pages = function(self, list, printFunction, confirmFunction, cancelFunction, extraOptions) -- Shows a list in page format with numerical options
        if self:get("page") == nil then self:set("page", 1) end
        
		local start = (self:get("page") - 1) * 10 + 1
		local stop = self:get("page") * 10
		if stop > #list then stop = #list end
		local left = self:get("page") > 1
		local right = self:get("page") * 10 + 1 < #list
		
		local option = nil
        
        draw:newline()
		if #list == 0 then
			draw:text("{gray68} Empty")
		else
			for i = start, stop do
                local inputTextPadding = #tostring(stop) - #tostring(i)
                local inputTextPrefix = tostring(i):sub(1, #tostring(i) - 1)
                local inputText = tostring(i):sub(-1)
				
				local text = "%s(%d) " % {inputTextPrefix, inputText}
				text = text..printFunction(list[i])
				
                draw:rect(color.gray28, 5 + inputTextPadding, draw.row, #tostring(i) + 2, 1)
				draw:text(text, 5 + inputTextPadding)
			end
		end
		
        if extraOptions then
            draw:newline()
            draw:options(extraOptions)
        end
        
        draw:newline()
        draw:hint("- Press [LEFT] and [RIGHT] to switch pages.")
        
		if self.key == "0" then self.key = "10"
        elseif self.key == "left" and left then self:add("page", -1)
        elseif self.key == "right" and right then self:add("page", 1)
        elseif self.key == "escape" then cancelFunction() end
		
		if isInRange(self.key, 1, #list - start + 1) then
            confirmFunction(list[tonumber(self.key) + start - 1])
        end
	end,
	
	quantity = function(self, maximum, confirmFunction, cancelFunction) -- Allows a quantity to be controlled
        draw:newline()
        draw:text("Currently seleced: {xp}%d{white} (Max: %d)." % {self:get("quantity"), maximum})
        
        draw:newline()
        draw:hint("- Press [LEFT] / [RIGHT] for min / max.")
        draw:hint("  Press [UP] / [DOWN] to change quantity.")
        draw:hint("  Press [ENTER] to confirm.")
        
        if self.key == "left" and maximum ~= 0 then self:set("quantity", 1)
        elseif self.key == "right" and maximum ~= 0 then self:set("quantity", maximum)
        elseif self.key == "up" and self:get("quantity") < maximum then self:add("quantity", 1)
        elseif self.key == "down" and self:get("quantity") > 1 then self:add("quantity", -1)
        elseif self.key == "return" and maximum ~= 0 then confirmFunction()
        elseif self.key == "escape" then cancelFunction() end
    end,
    
    input = function(self, lengthRange, confirmFunction, cancelFunction) -- Allow typing input from player
        if self:get("input") == nil then self:set("input", "") end
        love.keyboard.setKeyRepeat(true)
        
        draw:newline()
        draw:text(" : "..self:get("input").."_")
        
        draw:newline()
        draw:hint("- Please type an answer.")
        
        local length = #self:get("input")
        
        if length <= lengthRange[2] then
            if ("abcdefghijklmnopqrstuvwxyz1234567890,"):find(self.key) then
                if keyShift then self:add("input", self.key:upper())
                else self:add("input", self.key) end
            elseif self.key == "space" then
                self:add("input", " ")
            end
        end
        
        if self.key == "backspace" then 
            if length > 1 then self:set("input", self:get("input"):sub(1, length - 1))
            elseif length == 1 then self:set("input", "") end
        elseif self.key == "return" and length >= lengthRange[1] and length <= lengthRange[2] then
            love.keyboard.setKeyRepeat(false)
            confirmFunction()
        elseif self.key == "escape" then
            love.keyboard.setKeyRepeat(false)
            cancelFunction()
        end
    end,
    
    cancel = function(self) -- Returns true if escape or return are pressed
        if self.key == "return"  or self.key == "escape" then return true end
        return false
    end,
    
    
    -- SCREENS --
    
    title = function(self)
        draw:reset(10, 20)
        
        local magyka = {
            "  .x8888x.:d8888:.:d888b                                        ,688889,                    ",
            " X'  98888X:`88888:`8888!                           8L           !8888!                     ",
            "X8x.  8888X   888X  8888!                          8888!   .dL   '8888   ..                 ",
            "X8888 X8888   8888  8888'    .uu689u.   .uu6889u.  `Y888k:*888.   8888 d888L    .uu689u.    ",
            "'*888 !8888  !888* !888*   .888`*8888* d888`*8888    8888  888!   8888`*88**  .888`*8888*   ",
            "  `98  X888  X888  X888    8888  8888  8888  8888    8888  888!   8888 .d*.   8888  8888    ",
            "   '   X888  X888  8888    8888  8888  8888  8888    8888  888!   8888=8888   8888  8888    ",
            "   dx .8888  X888  8888.   8888  8888  8888  8888    8888  888!   8888 '888&  8888  8888    ",
            " .88888888*  X888  X888X.  8888.:8888  888&.:8888   x888&.:888'   8888  8888. 8888.:8888    ",
            "  *88888*    *888  `8888'  *888*'*888' *888*'8888.   *88*' 888  '*888*' 8888* *888*'*888*   ",
            "                                            '*8888         88F                              ",
            "..................................... .d88!   `888 ..... .98' ............................  ",
            " ..................................... 9888o.o88' ..... ./' ............................... ",
            "  ..................................... *68889*` ..... ~` ..... By Vincent G, aka Mutater ..",
        }
        
        for i = 1, 14 do
            draw:setColor{0.15, 0.55 - i/50, 0.5 + i/25}
            draw:text(magyka[i], 0, 0)
        end
        draw:setColor("white")
        
        draw:space(20)
        local option = input:options({"New Game", "Continue", "Options", "Quit"}, 10, 0)
        
        if option == "n" then devCommand("s")
        elseif option == "c" then self:down("continue")
        elseif option == "q" then love.event.quit() end
    end,
    
    newGame = function(self)
        
        -- Draw
        
        draw:initScreen(38, "screen/newGame")
        
        
        -- Get player name
        
        if self:get("stage") == "name" then
            draw:header("New Game - Name")
            
            draw:newline()
            draw:text("Please type your name. Your name must be between 2 and 15 characters long.")
            
            self:input(
                {2, 15},
                function()
                    self:set("name", self:get("input"))
                    self:set("stage", "class input")
                end,
                function() self:up() end
            )
        
        
        -- Get class choice
        
        elseif self:get("stage") == "class input" then
            draw:header("New Game - Class")
            
            draw:newline()
            draw:text("Choose your class.")
            
            draw:newline()
            draw:options({"Knight", "Warrior", "Rogue", "Spellsword", "Magye"})
            
            if self.key == "k" then self:set("class", newClass("Knight"))
            elseif self.key == "w" then self:set("class", newClass("Warrior"))
            elseif self.key == "r" then self:set("class", newClass("Rogue"))
            elseif self.key == "s" then self:set("class", newClass("Spellsword"))
            elseif self.key == "m" then self:set("class", newClass("Magye"))
            elseif self.key == "escape" then self:set("stage", "name") end
            
            if inString("kwrsm", self.key) then self:set("stage", "class output") end
        
        
        -- Display and confirm class choice
        
        elseif self:get("stage") == "class output" then
            draw:header("New Game - Class - "..self:get("class").name)
            
            draw:newline()
            for k, v in ipairs(self:get("class").description) do
                draw:text(v)
            end
            
            draw:newline()
            draw:text("Are you sure you wish to pick %s?" % self:get("class").name)
            
            draw:newline()
            draw:options({"Yes", "No"})
            
            if self.key == "y" then
                player:setClass(self:get("class"))
                player:set("name", self:get("name"))
                self:down("map")
                saving = true
                autosave = true
            elseif self.key == "n" or self.key == "escape" then self:set("stage", "class input") end
        end
    end,
    
    continue = function(self)
        
        -- Grab saves
        
        if self:get("saves") == nil then
            local saves = love.filesystem.getDirectoryItems("")
            self:set("saves", {})
            
            for k, v in ipairs(saves) do
                if love.filesystem.getRealDirectory(v) == love.filesystem.getSaveDirectory() then
                    table.insert(self:get("saves"), TSerial.unpack(love.filesystem.read(v)))
                end
            end
        end
        
        
        -- Draw
        
        draw:initScreen(38, "screen/continue")
        draw:header("Continue")
        
        
        -- Listing saves
        
        self:pages(
            self:get("saves"),
            function(save)
                return save.player.name
            end,
            function(save)
                world = newWorld(save)
                player = world:get("player")
                saving = true
                autosave = true
                self:down("map")
            end,
            function() if self.key == "escape" then self:up() end end,
            {"Open Save Directory"}
        )
        
        
        -- Input
        
        if self.key == "o" then love.system.openURL(love.filesystem.getSaveDirectory()) end
    end,
    
    map = function(self)
        
        -- Loads map if unloaded
        
        if self:get("map") == nil then self:set("map", newMap(world:get("currentMap"))) end
        
        
        -- Draw Variables
        
        local map = self:get("map")
        local x = world:get("playerX")
        local y = world:get("playerY")

        
        -- Drawing info and map
        
        draw:reset(0, 0)
        map:draw(x, y, self.width, self.height)
        draw:setColor("red")
        draw.autoSpace = false
        draw.autoSpace = true
        
        draw:reset(10, 20)
        draw:text("-= Map - %s =-" % world:get("currentMap"))
        
        draw:space(20)
        draw:mainStats(player, 20)
        
        draw:space(10)
        if self:get("hunting") then draw:text("Hunting: {green}True")
        else draw:text("Hunting: {red}False") end
        
        draw:space(10)
        local option = input:options({"Camp", "Hunt"}, 10)
        
        draw:space(20)
        draw:setColor("gray68")
        draw:text("- Use arrow keys to move.")
        
        
        -- Input Variables
        
        local moveX = 0
        local moveY = 0
        
        if option == "c" then self:down("camp") end
        if option == "h" then self:set("hunting", not self:get("hunting")) end
        if input.keyboard.left.justPressed  then moveX = moveX - 1 end
        if input.keyboard.right.justPressed then moveX = moveX + 1 end
        if input.keyboard.up.justPressed    then moveY = moveY - 1 end
        if input.keyboard.down.justPressed  then moveY = moveY + 1 end
        
        
        -- Collision Detection
        
        if not map:get("collision", x + moveX, y) then moveX = 0 end
        if not map:get("collision", x, y + moveY) then moveY = 0 end
        if not map:get("collision", x + moveX, y + moveY) then
            moveX = 0
            moveY = 0
        end
        
        
        -- Moving, finding portals, and determing encounters
        
        if moveX ~= 0 or moveY ~= 0 then
            world:add("playerX", moveX)
            world:add("playerY", moveY)
            
            local x = world:get("playerX")
            local y = world:get("playerY")
            local group = map:get("group", x, y)
            
            
            -- Check portals
            
            if map.data.portalTiles[y] then
                if map.data.portalTiles[y][x] then
                    local portal = map.data.portalTiles[y][x]
                    if portal.town then
                        world:set("playerX", portal.x + 1)
                        world:set("playerY", portal.y + 2)
                        self:set("portal", portal)
                        self:down("town")
                    elseif portal.teleport then
                        world:set("currentMap", portal.name)
                        world:set("playerX", portal.targetX)
                        world:set("playerY", portal.targetY)
                        self:set("map", newMap(portal.name))
                    end
                end
            end
            
            
            -- Determine encounters
            
            if group > 0 then
                local move = math.abs(moveX) + math.abs(moveY)
                if self:get("hunting") then self:add("steps", move)
                elseif rand(1, 20) == move then self:add("steps", move) end
                
                if self:get("steps") >= 20 then
                    local enemies = map:encounter(group)
                    self:set("steps", 0)
                    
                    if #enemies > 0 then
                        self:down("battle")
                        self:set("enemy", enemies)
                    end
                end
            end
        end
    end,
    
    town = function(self)
        
        -- Get town if nil
        
        if self:get("town") == nil then self:set("town", newTown(self:get("portal", "map").name)) end
        local town = self:get("town")
        
        
        -- Draw
        
        draw:initScreen(38, "screen/town")
        draw:header("Town - "..town.name)
        
        draw:newline()
        draw:mainStats(player)
        
        local storeNames = {}
        for k, v in ipairs{"General Store", "Blacksmith", "Arcanist", "Healer", "Alchemist"} do
            if town.stores[v] then table.insert(storeNames, v) end
        end
        appendTable(storeNames, {"Flea Market", "Inn"})
        
        draw:newline()
        draw:optionsNumbered(storeNames)
        
        
        -- Input
        
        if isInRange(self.key, 1, #storeNames) then
            local storeType = storeNames[tonumber(self.key)]
            self:down("store")
            self:set("items", town.stores[storeType])
            self:set("storeType", storeType)
        elseif self.key == "escape" then self:up() end
    end,
    
    store = function(self)
        local items = self:get("items")
        local storeType = self:get("storeType")
        
        -- Draw
        
        draw:initScreen(38, "screen/"..storeType)
        draw:header("Store - "..storeType)
        
        local options = {}
        local hasInventory = true
        
        if storeType == "Flea Market" then
            table.insert(options, "Sell")
            hasInventory = false
        elseif storeType == "Inn" then
            hasInventory = false
        elseif storeType == "Blacksmith" then table.insert(options, "Forge")
        elseif storeType == "Arcanist" then table.insert(options, "Enchant") end
        
        if #options > 0 then
            draw:newline()
            draw:options(options)
        end
        
        
        -- List store items
        
        if hasInventory then
            self:pages(
                items,
                function(item) return item:display().."  <gp> "..item:get("value") end,
                function(item)
                    self:down("inspectItemStore")
                    self:set("item", item, "inspectItemStore")
                end,
                function() self:up() end
            )
        elseif self.key == "escape" then self:up() end
        
        
        -- Input
        
        if self.key == "s" and storeType == "Flea Market" then self:down("inventorySell")
        elseif self.key == "f" and storeType == "Blacksmith" then
            self:down("crafting")
            self:set("station", "forge")
        end
    end,
    
    camp = function(self)
        
        -- Draw
        
        draw:reset()
        draw:text("-= Camp =-")
        
        draw:space(20)
        draw:mainStats(player)
        
        draw:space(20)
        local option = input:options({"Inventory", "Equipment", "Arts", "Crafting", "Quests", "Stats", "Options"}, 10)
        
        
        -- Input
        
        if option == "i" then self:down("inventory")
        elseif option == "e" then self:down("equipment")
        elseif option == "a" then self:down("arts")
        elseif option == "c" then
            self:down("crafting")
            self:set("station", "none")
        elseif option == "o" then self:down("options")
        elseif option == "escape" then self:up() end
    end,
    
    inventory = function(self)
        
        -- Draw
        
        draw:initScreen(38, "screen/inventory")
        draw:header("Inventory")
        
        
        -- List player inventory
        
		self:pages(
            player:get("inventory"),
            function(item)
                if item[1]:get("stackable") then return item[1]:display(item[2])
                else return item[1]:display() end
            end,
            function(item)
                self:down("inspectItem")
                self:set("item", item[1], "inspectItem")
            end,
            function() self:up() end
        )
    end,
    
    inventorySell = function(self)
        
        -- Draw
        
        draw:initScreen(38, "screen/inventory")
        draw:header("Inventory - Sell")
        
        
        -- List player inventory
        
		self:pages(
            player:get("inventory"),
            function(item) 
                if item[1]:get("stackable") then return item[1]:display(item[2])
                else return item[1]:display() end
            end,
            function(item)
                self:down("inspectItemSell")
                self:set("item", item[1], "inspectItemSell")
            end,
            function() self:up() end
        )
    end,
    
    inventoryBattle = function(self)
        
        -- Draw
        
		draw:initScreen(38, "screen/inventory")
        draw:header("Inventory - Battle")
		
        
        -- Load consumables in player inventory
        
		inventory = player:get("inventory")
		itemList = {}
		
		for k, v in ipairs(inventory) do
			if v[1]:get("consumable") then table.insert(itemList, v) end
		end
		
        
        -- List consumables
        
		self:pages(
            itemList,
            function(item)
                if item[1]:get("stackable") then return item[1]:display(item[2])
                else return item[1]:display() end
            end,
            function(item)
                self:down("inspectItemBattle")
                self:set("item", item[1], "inspectItemBattle")
            end,
            function() self:up() end
        )
    end,
    
    equipment = function(self)
        
        -- Draw
        
        draw:initScreen(38, "screen/equipment")
        draw:header("Equipment")
        
        
        -- Draw Equipment
        
        draw:newline()
        local playerEquipment = player:get("equipment")
        local i = 0
        for k, v in pairs(equipment) do
            i = i + 1
            if playerEquipment[v] ~= "" then draw:text("(%d) %s: %s" % {i, v, playerEquipment[v]:display(0)})
            else draw:text("(%d) %s: {gray48}None" % {i, v}) end
        end
        
        
        -- Input
        
        if isInRange(self.key, 1, 7) then
            local item = playerEquipment[equipment[tonumber(self.key)]]
            
            if item ~= "" then
                self:down("inspectItemEquipped")
                self:set("item", item, "inspectItemEquipped")
            end
        elseif self.key == "escape" then self:up() end
    end,
    
    arts = function(self)
        
        -- Draw
        
        draw:initScreen(38, "screen/arts")
        draw:header("Arts")
        
        
        -- List Arts
        
        self:pages(
            player:get("arts"),
            function(art)
                return art:display()
            end,
            function(art)
                self:down("inspectArt")
                self:set("art", art, "inspectArt")
            end,
            function() self:up() end
        )
    end,
    
    artsBattle = function(self)
        
        -- Draw
        
        draw:initScreen(38, "screen/arts")
        draw:header("Arts - Battle")
        
        
        -- List Arts
        
        self:pages(
            player:get("arts"),
            function(art)
                return art:display()
            end,
            function(art)
                self:down("inspectArtBattle")
                self:set("art", art, "inspectArtBattle")
            end,
            function() self:up() end
        )
    end,
    
    battle = function(self)
        draw:border(0)
        draw:rect("gray28", 39, 1, 2, self.height)
        draw:icon("battle/default", 41, 2, 5)
        
        
        -- Set up enemy images and spacing
        
        local enemyImages = {}
        local totalWidth = 0
        
        for k, v in ipairs(self:get("enemy")) do
            enemyImages[k] = {image = image["enemy/"..v:get("name")]}
            enemy = enemyImages[k]
            enemy.width = math.ceil(enemy.image:getWidth() / 2)
            enemy.height = math.ceil(enemy.image:getHeight() / 4)
            totalWidth = totalWidth + enemy.width
        end
        
        local altWidth = self.width - 42
        local spaces = #self:get("enemy") - 1
        
        local spaceBetweenEnemies = 2
        if spaces == 0 then spaceBetweenEnemies = 0
        else spacebetweenEnemies = 16 - (spaces * 2) end
        
        totalWidth = totalWidth + spaceBetweenEnemies * spaces
        
        local offset = math.floor((altWidth - totalWidth) / 2) + 42
        
        
        -- Draw enemies and enemy info
        
        for k, v in ipairs(self:get("enemy")) do
            local enemy = enemyImages[k]
            enemy.x = offset
            enemy.y = 27 - enemy.height
            local enemyCenter = enemy.x + math.floor(enemy.width / 2)
            local indexText = "(%d)" % {k}
            local indexX = enemyCenter - 1
            local nameX = enemyCenter - math.floor(#v:get("name") / 2)
            local levelText = "[Lvl %d]" % {v:get("level")}
            local levelX = enemyCenter - math.floor(#levelText / 2)
            local barX = enemyCenter - 4
            
            if v:get("hp") > 0 then
                draw:icon(enemy.image, enemy.x, enemy.y, 5)
                
                draw:text(indexText, indexX, enemy.y - 6)
                draw:text(v:get("name"), nameX, enemy.y - 4)
                draw:text(levelText, levelX, enemy.y - 3)
                draw:bar(v:get("hp"), v:get("stats").maxHp, color.hp, color.gray48, 8, "", "", barX, 28)
                draw:bar(v:get("mp"), v:get("stats").maxMp, color.mp, color.gray48, 8, "", "", barX, 29)
            end
            
            offset = offset + enemy.width + spaceBetweenEnemies
        end
        
        
        -- Draw player info
        
        draw:top()
        draw:header("Battle")
        
        draw:newline()
        draw:hpmp(player, 16)
        draw:newline()
        
        
        -- Set up turn order
        
        if self:get("stage") == "prebattle" then
            self:set("stage", "input")
            table.insert(self:get("turnOrder"), "player")
            
            for k, v in ipairs(self:get("enemy")) do table.insert(self:get("turnOrder"), k) end
        
        
        -- Update turn order and check for victory/defeat
        
        elseif self:get("stage") == "update" then
            
            -- Remove dead enemies from turn order
            
            for i = #self:get("turnOrder"), 1, -1 do
                if type(self:get("turnOrder")[i]) == "number" then
                    local enemy = self:get("enemy")[self:get("turnOrder")[i]]
                    if enemy:get("hp") <= 0 then table.remove(self:get("turnOrder"), i) end
                end 
            end
            
            
            -- Update battle if player or all enemies die
            
            if #self:get("turnOrder") == 1 and self:get("turnOrder")[1] == "player" then
                self:down("victory")
            elseif player:get("hp") <= 0 then
                self:down("defeat")
            else
                self:add("turn", 1)
                if self:get("turn") > #self:get("turnOrder") then self:set("turn", 1) end
                
                self:set("stage", "input")
            end
        
        
        -- Output damage text
        
        elseif self:get("stage") == "output" then
            draw:top()
            for k, v in pairs(self:get("text")) do draw:text(v, 42) end
            draw:newline()
            draw:rect(color.gray28, 43, draw.row, 13, 1)
            draw:text("[PRESS ENTER]", 43)
            if self.key == "return" then self:set("stage", "update") end
        
        
        -- Player's Turn
        
        elseif self:get("turnOrder")[self:get("turn")] == "player" then
            
            -- Choose action
            
            if self:get("stage") == "input" then
                self:set("text", {})
                
                draw:options({"Fight", "Art", "Guard", "Item", "Escape"})
                
                if self.key == "f" then
                    self:set("targetType", "enemy")
                    self:set("stage", "target")
                elseif self.key == "a" then
                    self:down("artsBattle")
                elseif self.key == "i" then
                    self:down("inventoryBattle")
                end
            
            
            -- Choose target
            
            elseif self:get("stage") == "target" then
                local autoSelect = self:get("targetType") == "enemy" and #self:get("enemy") == 1
                local targets = {}
                local index = 1
                local targetChosen = false
                
                
                -- Draw target options
                
                if self:get("targetType") ~= "enemy" then
                    draw:options({"Self"})
                    draw:newline()
                end
                
                for k, v in ipairs(self:get("enemy")) do
                    if v:get("hp") > 0 then
                        if not autoSelect then
                            draw:rect(color.gray28, 5, draw.row, 3, 1)
                            draw:text(" (%d) %s" % {index, v:get("name")})
                        end
                        index = index + 1
                        table.insert(targets, v)
                    end
                end
                
                
                -- Input
                
                if self.key == "s" and self:get("targetType") ~= "enemy" then
                    self:set("target", player)
                    targetChosen = true
                elseif isInRange(self.key, 1, index) or autoSelect then
                    local index = tonumber(self.key)
                    if autoSelect then index = 1 end
                    
                    local enemy = targets[index]
                    if enemy:get("hp") > 0 then
                        self:set("target", enemy)
                        targetChosen = true
                    end
                elseif self.key == "escape" then self:set("stage", "input") end
                
                
                -- Do damage based off of selected option
                
                if targetChosen then
                    if self:get("itemChosen") then
                        for k, v in ipairs(self:get("item"):get("effect")) do
                            appendTable(self:get("text"), v:use(self:get("item"), player, self:get("target")))
                        end
                        self:set("itemChosen", false)
                    elseif self:get("artChosen") then
                        for k, v in ipairs(self:get("art"):get("effect")) do
                            appendTable(self:get("text"), v:use(self:get("art"), player, self:get("target")))
                        end
                        self:set("artChosen", false)
                    else
                        appendTable(self:get("text"), player:attack(self:get("target")))
                    end
                    
                    appendTable(self:get("text"), player:updatePassives())
                    self:set("stage", "output")
                end
            end
        
        
        -- Enemy's Turn
        
        elseif type(self:get("turnOrder")[self:get("turn")]) == "number" then
            
            -- AI coming soon!
            
            local enemy = self:get("enemy")[self:get("turnOrder")[self:get("turn")]]
            
            if self:get("stage") == "input" then
                self:set("text", {})
                appendTable(self:get("text"), enemy:attack(player))
                appendTable(self:get("text"), enemy:updatePassives())
                self:set("stage", "output")
            end
        end
    end,
    
    victory = function(self)
        
        -- Draw
        
        draw:initScreen(38, "screen/victory")
        draw:header("Victory")
        
        draw:newline()
        draw:hpmp(player)
        
        draw:newline()
        draw:text("You won! Good job.")
        
        local lootEntity = self:get("lootEntity")
        
        
        -- Get enemy drops
        
        if self:get("stage") == "input" then
            for k, v in ipairs(self:get("enemy", "battle")) do
                lootEntity.gp = lootEntity.gp + rand(v.drops.gp)
                lootEntity.xp = lootEntity.xp + rand(v.drops.xp)
                for _, item in ipairs(v:get("drops"):drop()) do
                    lootEntity:addItem(item[1], item[2])
                end
            end
            
            if lootEntity.gp then player:add("gp", lootEntity.gp) end
            if lootEntity.xp then player:add("xp", lootEntity.xp) end
            for k, v in ipairs(lootEntity:get("inventory")) do
                player:addItem(v[1], v[2])
            end
            
            hp = math.floor(player:get("stats").maxHp * 0.66)
            mp = math.floor(player:get("stats").maxMp * 0.66)
            
            if hp > player:get("hp") then player:set("hp", hp) end
            if mp > player:get("mp") then player:set("mp", mp) end
            
            self:set("stage", "output")
        
        
        -- Show drops
        
        elseif self:get("stage") == "output" then
            draw:newline()
            draw:text("Obtained:")
            draw:text(" GP: <gp> "..lootEntity.gp)
            draw:text(" XP: <xp> "..lootEntity.xp)
            
            if #lootEntity:get("inventory") > 0 then
                draw:newline()
                draw:text(" Items:")
                for k, v in ipairs(lootEntity:get("inventory")) do
                    local item = ""
                    if v[1]:get("stackable") then item = v[1]:display(v[2])
                    else item = v[1]:display() end
                    
                    draw:text(" - "..item)
                end
            end
            
            if self:cancel() then self:upPast("battle") end
        end
    end,
    
    defeat = function(self)
        
        -- Draw
        
        draw:initScreen(38, "screen/defeat")
        draw:header("Defeat")
        
        draw:newline()
        draw:hpmp(player)
        
        draw:newline()
        draw:text("You lost!")
        
        draw:newline()
        draw:text("The sound of oars treading water draws near.")
        
        
        -- Apply Charon's Curse
        
        if self:get("stage") == "curse" then
            player:set("hp", math.floor(player:get("stats").maxHp * 0.5))
            player:set("mp", math.floor(player:get("stats").maxMp * 0.5))
            player:applyPassive(newEffect("Charon's Curse"))
            self:set("stage", "input")
        
        
        -- Wait
        
        elseif self:get("stage") == "input" then
            if self:cancel() then self:upPast("battle") end
        end
    end,
    
    inspectItem = function(self)
        local item = self:get("item")
        
        
        -- Draw
        
        draw:initScreen(38, "screen/inspectItem")
        draw:imageSide("item/"..item:get("name"), "item/default")
        
        draw:top()
        draw:header("Inspect Item")
        
        draw:newline()
        draw:hpmp(player)
        
        draw:newline()
        draw:newline()
        local quantity = 0
        if item:get("stackable") then quantity = player:numOfItem(item) end
        draw:item(item, quantity)
        
        
        -- Input
        
        if self:get("stage") == "input" then
            draw:newline()
            if item:get("consumable") then draw:options({"Use", "Discard"})
            elseif item:get("equipment") then draw:options({"Equip", "Discard"})
            else draw:options({"Discard"}) end
            
            if self.key == "e" and item:get("equipment") then
                player:equip(item)
                self:set("stage", "equip")
            elseif self.key == "u" and item:get("consumable") then
                for k, v in ipairs(item:get("effect")) do
                    appendTable(self:get("text"), v:use(item, player, player))
                end
                if not item:get("infinite") then player:removeItem(item) end
                
                self:set("stage", "use")
            elseif self.key == "d" then
                if item:get("stackable") then
                    self:set("stage", "discard")
                else
                    player:removeItem(item)
                    self:set("quantity", 0)
                    
                    self:set("stage", "discard output")
                end
            elseif self.key == "escape" then self:up() end
        
        
        -- Equip Output
        
        elseif self:get("stage") == "equip" then
            draw:newline()
            draw:text("Equipped "..item:display()..".")
            draw:newline()
            draw:hint("- Press [ENTER] to continue.")
            
            if self:cancel() then self:up() end
        
        
        -- Use Output
        
        elseif self:get("stage") == "use" then
            draw:newline()
            for k, v in ipairs(self:get("text")) do draw:text(v) end
            
            draw:newline()
            draw:hint("- Press [ENTER] to continue.")
            
            if self:cancel() then self:set("stage", "output") end
        
        
        -- Discard Quantity
        
        elseif self:get("stage") == "discard" then
            self:quantity(player:numOfItem(item), function() self:set("stage", "discard output") end, function() self:set("stage", "input") end)
        
        
        -- Discard Output
        
        elseif self:get("stage") == "discard output" then
            local discardText = ""
            if quantity == 1 and not item:get("stackable") then discardText = item:display()
            else discardText = item:display(self:get("quantity")) end
            
            draw:newline()
            draw:text("Discarded %s." % {discardText})
            draw:newline()
            draw:hint("- Press [ENTER] to continue.")
            
            if self:cancel() then
                player:removeItem(item, self:get("quantity"))
                self:set("stage", "output")
            end
        
        
        -- Decide whether to go up or stay
        
        elseif self:get("stage") == "output" then
            if player:numOfItem(item) == 0 or not item:get("stackable") then self:up()
            else
                self:set("text", {})
                self:set("stage", "input")
            end
        end
    end,
    
    inspectItemSell = function(self)
        local item = self:get("item")
        
        
        -- Draw
        
        draw:initScreen(38, "screen/inspectItem")
        draw:imageSide("item/"..item:get("name"), "item/default")
        
        draw:top()
        draw:header("Inspect Item - Sell")
        
        draw:newline()
        local quantity = 0
        if item:get("stackable") then quantity = player:numOfItem(item) end
        draw:item(item, quantity)
        
        
        -- Input
        
        if self:get("stage") == "input" then
            draw:newline()
            draw:options({"Sell"})
            draw:newline()
            
            if self.key == "s" then
                if item:get("stackable") then
                    self:set("stage", "sell")
                else
                    player:removeItem(item)
                    self:set("quantity", 1)
                    self:set("stage", "sell output")
                end
            elseif self.key == "escape" then self:up() end
        
        
        -- Sell Quantity
        
        elseif self:get("stage") == "sell" then
            self:quantity(player:numOfItem(item), function() self:set("stage", "sell output") end, function() self:set("stage", "input") end)
        
        
        -- Sell Output
        
        elseif self:get("stage") == "sell output" then
            local sellText = ""
            if self:get("quantity") == 1 and not item:get("stackable") then sellText = item:display()
            else sellText = item:display(self:get("quantity")) end
            
            local sellValue = math.ceil(item:get("value") * self:get("quantity") * 0.67)
            sellText = sellText.." for <gp>{gp} {white}%d" % {sellValue}
            
            draw:newline()
            draw:text("Sold %s." % {sellText})
            draw:newline()
            draw:hint("- Press [ENTER] to continue.")
            
            if self:cancel() then
                player:removeItem(item, self:get("quantity"))
                player:add("gp", sellValue * self:get("quantity"))
                
                if player:numOfItem(item) == 0 or not item:get("stackable") then self:up()
                else self:set("stage", "input") end
            end
        end
    end,
    
    inspectItemStore = function(self)
        local item = self:get("item")
        
        
        -- Draw
        
        draw:initScreen(38, "screen/inspectItem")
        draw:imageSide("item/"..item:get("name"), "item/default")
        
        draw:top()
        draw:header("Inspect Item - Purchase")
        
        draw:newline()
        draw:item(item)
        
        
        -- Purchase Quantity
        
        if self:get("stage") == "input" then
            local maxBuy = math.floor(player:get("gp") / item:get("value"))
            self:quantity(maxBuy, function() self:set("stage", "output") end, function() self:up() end)
        
        
        -- Purchase Output
        
        elseif self:get("stage") == "output" then
            local buyText = ""
            if quantity == 1 and not item:get("stackable") then buyText = item:display()
            else buyText = item:display(self:get("quantity")) end
            
            draw:newline()
            draw:text("Bought %s." % {buyText})
            draw:newline()
            draw:hint("- Press [ENTER] to continue.")
            
            if self:cancel() then
                player:addItem(newItem(item), self:get("quantity"))
                player:add("gp", -self:get("quantity") * item:get("value"))
                self:up()
            end
        end
    end,
    
    inspectItemEquipped = function(self)
        local item = self:get("item")
        
        
        -- Draw
        
        draw:initScreen(38, "screen/inspectItem")
        draw:imageSide("item/"..item:get("name"), "item/default")
        
        draw:top()
        draw:header("Inspect Item - Equipped")
        
        draw:newline()
        draw:item(item)
        
        draw:newline()
        draw:options({"Unequip"})
        
        
        -- Input
        
        if self.key == "u" then
            player:unequip(item)
            self:up()
        elseif self.key == "escape" then self:up() end
    end,
    
	inspectItemBattle = function(self)
        local item = self:get("item")
		
        
        -- Draw
        
        draw:initScreen(38, "screen/inspectItem")
        draw:imageSide("item/"..item:get("name"), "item/default")
        
        draw:top()
        draw:header("Inspect Item - Battle")
        
        draw:newline()
        draw:item(item)
		
        draw:newline()
        draw:options({"Use"})
        
        
        -- Input
        
        if self.key == "u" and item:get("consumable") then
            self:set("itemChosen", true, "battle")
            self:set("item", item, "battle")
            self:set("targetType", "all", "battle")
            self:set("stage", "target", "battle")
            self:upPast("inventoryBattle")
        elseif self.key == "escape" then
            self:set("itemChosen", false, "battle")
            self:up()
        end
	end,
	
    inspectArt = function(self)
        local art = self:get("art")
        
        
        -- Draw
        
        draw:initScreen(38, "screen/inspectArt")
        draw:imageSide("art/"..art:get("name"), "art/default")
        
        draw:top()
        draw:header("Inspect Art")
        
        draw:newline()
        draw:item(art)
        
        
        -- Input
        
        if self:get("stage") == "input" then
            if self.key == "escape" then self:up() end
        end
    end,
    
    inspectArtBattle = function(self)
        local art = self:get("art")
        
        
        -- Draw
        
        draw:initScreen(38, "screen/inspectArt")
        draw:imageSide("art/"..art:get("name"), "art/default")
        
        draw:top()
        draw:header("Inspect Art - Battle")
        
        draw:newline()
        draw:item(art)
        
        draw:newline()
        draw:options({"Use"})
        
        
        -- Input
        
        if self.key == "u" then
            self:set("artChosen", true, "battle")
            self:set("art", art, "battle")
            self:set("targetType", "all", "battle")
            self:set("stage", "target", "battle")
            self:upPast("artsBattle")
        elseif self.key == "escape" then
            self:set("artChosen", false, "battle")
            self:up()
        end
    end,
    
    crafting = function(self)
        
        -- Draw
        
        draw:initScreen(38, "screen/craftItem")
        local division = " - "..self:get("station")
        if self:get("station") == "none" then division = "" end
        draw:header("Craft"..division)
        
        
        -- List crafting recipes
        
        local _recipes = {}
        for k, v in ipairs(player:get("recipes")) do
            if v:get("station") == self:get("station") then table.insert(_recipes, v) end
        end
        
        self:pages(
            _recipes,
            function(recipe)
                local item = recipe:get("item")
                if item:get("stackable") then return item:display(recipe:get("quantity"))
                else return item:display() end
            end,
            function(recipe)
                self:down("craftItem")
                self:set("recipe", recipe, "craftItem")
            end,
            function() self:up() end
        )
    end,
    
    craftItem = function(self)
        local recipe = self:get("recipe")
        local item = recipe:get("item")
        
        
        -- Draw
        
        draw:initScreen(38, "screen/craftItem")
        draw:imageSide("item/"..item:get("name"), "item/default")
        
        draw:top()
        draw:header("Craft - Item")
        
        draw:newline()
        draw:item(item)
        
        
        -- Display ingredients and determine max craft
        
        local craftable = true
        local numCraftable = 99999999
        for k, v in pairs(recipe:get("ingredients")) do
            local owned = player:numOfItem(k)
            
            if owned < v then
                craftable = false
                numCraftable = 0
            elseif math.floor(owned / v) < numCraftable then
                numCraftable = math.floor(owned / v)
            end
            
            draw:text("%dx %s (%d/%d)" % {v, newItem(k):display(), owned, v})
        end
        
        if item:get("equipment") and craftable then numCraftable = 1 end
        
        
        -- Craft Quantity
        
        if self:get("stage") == "input" then
            self:quantity(
                numCraftable,
                function() self:set("stage", "output") end,
                function() up() end
            )
        
        
        -- Craft Output
        
        elseif self:get("stage") == "output" then
            draw:newline()
            draw:text("Crafted %s." % item:display())
            
            if self:cancel() then
                for k, v in pairs(recipe:get("ingredients")) do
                    player:removeItem(k, v * self:get("quantity"))
                end
                player:addItem(newItem(item), self:get("quantity"))
                
                self:up()
            end
        end
    end,

    options = function(self)
        draw:initScreen(38, "screen/options")
        draw:header("Options")
        
        draw:newline()
        draw:options({"Audio", "Video", "Binds", "Misc"})
        
        if self:cancel() then self:up() end
    end,
    
    quit = function(self)
        
        -- Draw
        
        draw:initScreen(38, "screen/quit")
        draw:header("Quit")
        
        draw:newline()
        draw:text("Save before you quit?")
        
        draw:newline()
        draw:options({"Yes", "No"})
        
        draw:newline()
        
        
        -- Input
        
        if self.key == "y" then
            love.filesystem.write(player:get("name"), TSerial.pack(world:export(), false, true))
            os.exit()
        elseif self.key == "n" then
            os.exit()
        elseif self.key == "escape" then
            self:up()
            return true
        end
    end
}