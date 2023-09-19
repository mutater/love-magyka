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
        title = {saves=nil, index=0},
        newGame = {name="", stage="name", class=nil},
        continue = {saves=nil, index=0},
        map = {map=nil, portal=nil, hunting=false, steps=0},
        town = {town=nil, index=0},
        store = {items=nil, storeType=""},
        battle = {
            turn = 1,
            turnOrder = {},
            stage = "prebattle",
            enemy = {},
            text = {},
            item = nil,
            itemChosen = false,
            targetType = "",
            target = "",
            index = 0,
            escape = false,
        },
        inventory = {stage="type input", itemType="", quantity=1, items=nil, inventoryPurpose="inventory", text={}, battle=false, index=0, typeIndex=0},
        victory = {stage="input", lootEntity=newEntity{}},
        defeat = {stage="curse"},
        craft = {station="none"},
        craftItem = {stage="input", recipe=nil, quantity=0},
    },
    key = "",
    
    -- Functionality Functions
    
    update = function(self, dt) -- Executes current screen
        self[self.current](self)
        self.key = ""
    end,
    
    up = function(self, args) -- Goes up a screen
        if self.branch[1] == nil then return end
        
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
        if name == "camp" then
            self.branch = {}
            self.branchData = {}
        end
        
        args = args or {}
        self.branchData[name] = deepcopy(self.branchDataDefaults[name])
        updateTable(self.branchData[name], args)
        if name ~= "camp" then table.insert(self.branch, self.current) end
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
    
    quantity = function(self, maximum, confirmFunction, cancelFunction) -- Allows a quantity to be controlled
        draw:space()
        draw:text("Currently seleced: {xp}%d{white} (Max: %d)." % {self:get("quantity"), maximum})
        
        draw:space()
        if input:textButton("- Mouse over or hold [F1] for help.", 0, 0, color.gray4, color.gray4, color.gray4) == "hovered" or input.keyboard.f1.pressed then
            draw:text("  Press [UP] / [DOWN] or use [MOUSEWHEEL] to change quantity.")
            draw:text("  Press [LEFT] / [RIGHT] or use [SHIFT] + [MOUSEWHEEL] for min / max.")
            draw:text("  Press [ENTER] or [MOUSE1] to confirm.")
            draw:text("  Press [ESCAPE] or [MOUSE2] to cancel.")
        end
        
        option = input:optionsNoGUI("", {"left", "right", "up", "down", "enter"})
        
        if option == "left" then self:set("quantity", 1)
        elseif option == "right" then self:set("quantity", maximum)
        elseif option == "up" then self:add("quantity", 1)
        elseif option == "down" then self:add("quantity", -1) end
        
        if keyShift then
            if input.mouseWheel.y > 0 then self:set("quantity", maximum) end
            if input.mouseWheel.y < 0 then self:set("quantity", 1) end
        else self:add("quantity", input.mouseWheel.y) end
        
        if self:enter() and maximum ~= 0 then confirmFunction() end
        if self:cancel() then cancelFunction() end
        
        if self:get("quantity") > maximum then self:set("quantity", maximum) end
        if self:get("quantity") < 1 then self:set("quantity", 1) end
    end,
    
    drawPage = function(self, title, width, receiveInput) -- Draws the page background
        draw.autoSpace = false
        
		if receiveInput then draw:setColor("gray2")
		else draw:setColor("gray15") end
        
		draw:rectangle("fill", 0, 0, width, draw.screenHeight)
		draw:setColor("gray15")
		draw:rectangle("fill", 0, 0, width, 3)
		draw:setColor("black")
		draw:rectangle("line", 0, -1, width, draw.screenHeight + 2)
		draw.autoSpace = true
		
		draw:shift()
		draw:space()
        
		if receiveInput then draw:setColor()
		else draw:setColor("gray4") end
        
		draw:text(title)
        draw:text(string.rep("-", strLen(title)))
    end,
    
	page = function(self, title, width, list, indexString, receiveInput, displayFunction, infoFunction) -- Draws a list of options on a page
		self:drawPage(title, width, receiveInput)
		
		local displays = {}
		local infos = {}
		local indexes = {}
		
		for k, v in ipairs(list) do
			table.insert(displays, displayFunction(k, v))
			if infoFunction then table.insert(infos, infoFunction(k, v)) end
			table.insert(indexes, k)
		end
		
		local option = nil
		
		draw:space()
        if infoFunction then
            draw.autoSpace = false
            draw.overrideIcon = not receiveInput
            
            if not receiveInput then draw:setColor("gray4") end
            
            for k, v in ipairs(infos) do
                draw:text(rjust(v, width - 2), 0, (k - 1) * 2)
            end
            draw.autoSpace = true
            draw.overrideIcon = false
        end
        
		if receiveInput then
			option, index = input:optionsList(displays, self:get(indexString), 1)
			self:set(indexString, index)
		else
			draw:setColor("gray4")
			for k, v in ipairs(displays) do
                local text = cleanText(v)
				if k == self:get(indexString) then draw:text(" - "..text)
				else draw:text(text) end
				draw:space()
			end
		end
        
		if option == "escape" then return option
		elseif option ~= "" then return indexes[tonumber(option)] end
		
		return nil
	end,
	
    input = function(self, lengthRange, confirmFunction, cancelFunction) -- Allow typing input from player
        if self:get("input") == nil then self:set("input", "") end
        love.keyboard.setKeyRepeat(true)
        
        draw:space()
        draw:text(" : "..self:get("input").."_")
        
        draw:space()
        draw:hint("- Please type an answer.")
        
        local length = #self:get("input")
        
        if length <= lengthRange[2] then
            if ("abcdefghijklmnopqrstuvwxyz1234567890,"):find(input.lastKey) then
                if keyShift then self:add("input", input.lastKey:upper())
                else self:add("input", input.lastKey) end
            elseif input.lastKey == "space" then
                self:add("input", " ")
            end
        end
        
        if input.lastKey == "backspace" then 
            if length > 1 then self:set("input", self:get("input"):sub(1, length - 1))
            elseif length == 1 then self:set("input", "") end
        elseif input.keyboard.enter.justPressed and length >= lengthRange[1] then
            love.keyboard.setKeyRepeat(false)
            confirmFunction()
        elseif input.keyboard.escape.justPressed or input.mouse[2].justPressed then
            love.keyboard.setKeyRepeat(false)
            cancelFunction()
        end
    end,
    
    cancel = function(self) -- Returns true if escape or return are pressed
        return input.keyboard.escape.justPressed or input.mouse[2].justReleased
    end,
    
    enter = function(self) -- Returns true if enter or left mouse are pressed
        return input.keyboard.enter.justPressed or input.mouse[1].justReleased
    end,
    
    
    -- SCREENS --
    
    title = function(self)
        
        -- Draw Title
        
        draw:reset(28)
        
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
        
        
        -- Options List
        
        draw:setColor()
        draw:space()
        draw:shift()
        local option = input:options({"New Game", "Open Save Directory", "Quit"})
        
        if option == "n" then self:down("newGame")
        elseif option == "o" then love.system.openURL(love.filesystem.getSaveDirectory())
        elseif option == "q" then love.event.quit() end
        
        
        -- Continue Game
        
        if self:get("saves") == nil or #love.filesystem.getDirectoryItems("") ~= #self:get("saves") then
            local saves = love.filesystem.getDirectoryItems("")
            self:set("saves", {})
            
            for k, v in ipairs(saves) do
                if love.filesystem.getRealDirectory(v) == love.filesystem.getSaveDirectory() then
                    table.insert(self:get("saves"), TSerial.unpack(love.filesystem.read(v)))
                end
            end
        end
        
		local saves = self:get("saves")
		
		draw:reset(2, 0)
		local index = self:page(
			"Continue Game", 24, saves, "index", #saves ~= 0,
			function(k, v) return v.player.info.name end
		)
		
		if index then
			world = newWorld(saves[index])
            player = world:get("player")
            saving = true
            autosave = true
            self:down("camp")
		end
    end,
    
    newGame = function(self)
        
        -- Draw
        
        draw:reset()
        
        
        -- Get player name
        
        if self:get("stage") == "name" then
            draw:text("-= New Game - Name =-")
            
            draw:space()
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
            draw:text("-= New Game - Class =-")
            
            draw:space()
            draw:text("Choose your class.")
            
            draw:space()
            local option = input:options({"Knight", "Warrior", "Rogue", "Spellsword", "Magye"})
            
            if option == "k" then self:set("class", newClass("Knight"))
            elseif option == "w" then self:set("class", newClass("Warrior"))
            elseif option == "r" then self:set("class", newClass("Rogue"))
            elseif option == "s" then self:set("class", newClass("Spellsword"))
            elseif option == "m" then self:set("class", newClass("Magye"))
            elseif option == "escape" then self:set("stage", "name") end
            
            if inString("kwrsm", option) then self:set("stage", "class output") end
        
        
        -- Display and confirm class choice
        
        elseif self:get("stage") == "class output" then
			local class = self:get("class")
			local info = class.info
			
            draw:text("-= New Game - Class - "..info.name.." =-")
            
            draw:space()
            for k, v in ipairs(info.description) do draw:text(v) end
            
            draw:space()
            draw:text("Are you sure you wish to pick %s?" % info.name)
            
            draw:space()
            local option = input:options({"Yes", "No"})
            
            if option == "y" then
                player:setClass(class)
				player.info.name = self:get("name")
                self:down("camp")
                saving = true
                autosave = true
            elseif option == "n" or option == "escape" then
				self:set("stage", "class input")
			end
        end
    end,
    
    camp = function(self)
        -- Draw
        
        draw:reset()
        draw:text("-= Camp =-")
        
        draw:space()
        draw:mainStats(player)
        
        draw:space()
        draw:shift()
        local option1 = input:options({"Encounter", "Town", "Options"})
        
        draw:space()
        local option2 = input:options({"Inventory", "Crafting", "Quests", "Stats"})
        
        local option = concat(option1, option2)
        
        draw:space()
        if input:textButton("- Mouse over or hold [F1] for help.", 0, 0, color.gray4, color.gray4, color.gray4) == "hovered" or input.keyboard.f1.pressed then
            draw:reset(19, 9)
            draw:setColor("gray4")
            draw:text("- Hunt for enemies here. THIS IS WHERE YOU SHOULD START.")
            draw:space()
            draw:text("- Buy & sell items, find quests, and more here. Visit this area after your first battle.")
            draw:space()
            draw:text("- WIP")
            draw:space()
            draw:text("- See what you have and what you have equipped here.")
            draw:space()
            draw:text("- Craft various items from parts purchased, made, or found.")
            draw:space()
            draw:text("- WIP")
            draw:space()
            draw:text("- WIP")
        end
        
        -- Input
        
        if option == "e" then
        do
            local enemy = {}
            local num = rand(1, 99)
            local quantity = 0
            
            if num <= 35 then quantity = 1
            elseif num <= 85 then quantity = 2
            elseif num <= 92 then quantity = 3
            elseif num <= 96 then quantity = 4
            elseif num <= 98 then quantity = 5
            elseif num == 99 then quantity = 6 end
            
            local minLevel = player:get("level") - 2
            local maxLevel = player:get("level") + 2
            
            if player:get("level") <= 2 then
                minLevel = 1
                maxLevel = player:get("level") + 1
            end
            
            local enemyNames = getNamesFromDatabase("Entity")
            local levelToNameDict = {}
            
            for i = #enemyNames, 1, -1 do
                local level = newEntity(enemyNames[i]):get("level")
                if level < minLevel or level > maxLevel then table.remove(enemyNames, i)
                else
                    if levelToNameDict[level] == nil then levelToNameDict[level] = {} end
                    
                    table.insert(levelToNameDict[level], enemyNames[i])
                end
            end
            
            for i = 1, quantity do
                local level = rand(minLevel, maxLevel)
                local t = levelToNameDict[level]
                
                table.insert(enemy, newEntity(t[rand(1, #t)]))
            end
            
            self:down("battle")
            self:set("enemy", enemy)
        end
        elseif option == "t" then self:down("town")
        elseif option == "i" then self:down("inventory")
        elseif option == "c" then
            self:down("inventory")
            self:set("inventoryPurpose", "craft")
        elseif option == "q" then --self:down("quests")
        elseif option == "s" then self:down("stats")
        elseif option == "o" then --[[self:down("options")]] end
    end,
    
    map = function(self)
        -- oh fuck man find a different way
    end,
    
    town = function(self)
        
        -- Get town if nil
        
        if self:get("town") == nil then self:set("town", newTown("Town")) end
        local town = self:get("town")
        
        
        -- Draw
        
        draw:reset()
        draw:text("-= Town - "..town.name.." =-")
        
        draw:space()
        draw:mainStats(player)
        
        local storeNames = {}
        for k, v in ipairs{"General Store", "Blacksmith", "Arcanist", "Healer", "Alchemist"} do
            if town.stores[v] then table.insert(storeNames, v) end
        end
        appendTable(storeNames, {"Flea Market", "Inn"})
        
        draw:space()
        local option, index = input:optionsList(storeNames, self:get("index"), 1)
        self:set("index", index)
        
        
        -- Input
        
        if option == "escape" then
            self:up()
        elseif option ~= "" then
            local storeType = storeNames[index]
            self:set("items", town.stores[storeType])
            self:set("storeType", storeType)
            self:down("inventory")
            self:set("stage", "item input")
            self:set("itemType", "all")
            if storeType == "Flea Market" then self:set("inventoryPurpose", "sell")
            else self:set("inventoryPurpose", "store") end
        end
    end,
    
    inventory = function(self)
        local col1 = 2
        local col1Width = math.ceil(draw.screenWidth * 0.15)
        local col2 = col1 + col1Width + 2
        local col2Width = math.ceil(draw.screenWidth * 0.3)
        local col3 = col2 + col2Width + 2
        local col3Width = draw.screenWidth - col3 - 2
    
	
        -- Type Select
        
        do
            draw:reset(col1, 0)
            
            local types = {"all"}
            if not has({"store", "select", "sell", "craft"}, "inventoryPurpose") then table.insert(types, "character") end
            appendTable(types, Globals.itemTypes)
            local capitalTypes = title(deepcopy(types))
            
            self:drawPage(title(self:get("inventoryPurpose")), col1Width, self:get("stage") == "type input")
            draw:space()
            local index = input:optionsIndex(capitalTypes, self:get("stage") == "type input")
            
            if index == "escape" then
                self:up()
                return
            elseif index then
                if types[index] ~= self:get("itemType") then self:set("index", 0) end
                self:set("itemType", types[index])
                self:set("stage", "item input")
                input:update()
            end
        end
        
        
        -- Item Select
        
        if self:get("stage") ~= "type input" then
            draw:reset(col2, 0)
            
            -- Setting up pages function
            
            local items = {}
            local displayFunction = nil
            local infoFunction = nil
            
            if self:get("itemType") == "character" then
                for k, v in pairs(equipment) do
                    table.insert(items, player:get("equipment")[v])
                end
                
                displayFunction = function(k, v)
                    if type(v) == "string" then
                        return title(equipment[k])..":"
                    else
                        return "%s: %s" % {title(v:get("slot")), v:display()}
                    end
                end
            elseif self:get("inventoryPurpose") == "store" then
                if self:get("itemType") == "all" then
                    items = self:get("items", "town")
                else
                    for k, v in ipairs(self:get("items", "town")) do
                        if v:get("type") == self:get("itemType") then table.insert(items, v) end
                    end
                end
                
                displayFunction = function(k, v) return v:display() end
                infoFunction = function(k, v) return "%d <gp>" % v:get("value") end
            elseif self:get("inventoryPurpose") == "craft" then
                if self:get("itemType") == "all" then
                    for k, v in ipairs(player:get("recipes")) do
                        table.insert(items, v.item)
                    end
                else
                    for k, v in ipairs(player:get("recipes")) do
                        if v:get("item"):get("type") == self:get("itemType") then table.insert(items, v.item) end
                    end
                end
                
                displayFunction = function(k, v) return v:display() end
                infoFunction = function (k, v) return v:info() end
            else
                if self:get("itemType") == "all" then
                    items = player.inventory.list
                else
                    for k, v in ipairs(player.inventory.list) do
                        if v[1]:get("type") == self:get("itemType") then table.insert(items, v) end
                    end
                end
                
                displayFunction = function(k, v) return v[1]:display() end
                infoFunction = function(k, v) return v[1]:info() end
            end
            
            -- Pages
            
            local index = self:page(
                "Items - "..title(self:get("itemType")), col2Width, items, "index",
                self:get("stage") == "item input",
                displayFunction,
                infoFunction
            )
            
            -- Display gold
            
            if has({"store", "sell"}, self:get("inventoryPurpose")) then
                draw:reset(col2, 0)
                draw:space()
                draw:text(rjust("<gp> Gold: %d" % player:get("gp"), col2Width - 1))
            end
            
            -- Options
            
            if index == "escape" then
                if self:get("inventoryPurpose") == "store" then
                    self:up()
                    return
                else self:set("stage", "type input") end
            elseif index and items[index] ~= "" then
                self:set("stage", "inspect")
                self:set("inspect stage", "input")
                self:set("item", items[index])
                input:update()
            end
        end
        
        
        -- Inspect
        
        if self:get("stage") == "inspect" then
            draw:reset(col3, 0)
            draw:setColor("gray2")
            draw:rectangle("fill", 0, 0, col3Width, draw.screenHeight)
            draw:setColor("gray15")
            draw:rectangle("line", 0, -1, col3Width, draw.screenHeight + 2)
            
            draw:reset(col3, 1)
            draw:shift()
            local item = self:get("item")[1]
            if has({"store", "craft"}, self:get("inventoryPurpose")) or self:get("itemType") == "character" then
                item = self:get("item")
            end
            
            if self:get("inventoryPurpose") == "inventory" then
                draw:hpmp(player)
                draw:space()
            end
            
            local quantity = 0
            if item:get("stackable") then
                quantity = player:numOfItem(item)
                draw:item(item, quantity)
            else
                quantity = 1
                draw:item(item)
            end
            
            
            -- Store Inventory
            
            if self:get("inventoryPurpose") == "store" then
                
                -- Input
            
                if self:get("inspect stage") == "input" and self:get("inventoryPurpose") == "store" then
                    self:quantity(
                        math.floor(player:get("gp") / item:get("value")),
                        function()
                            player:addItem(newItem(item), self:get("quantity"))
                            player:add("gp", -self:get("quantity") * item:get("value"))
                            self:set("inspect stage", "output")
                        end,
                        function() self:set("stage", "item input") end
                    )
                
                
                -- Output
                
                elseif self:get("inspect stage") == "output" then
                    local buyText = ""
                    if quantity == 1 and not item:get("stackable") then buyText = item:display()
                    else buyText = item:display(self:get("quantity")) end
                    
                    draw:space()
                    draw:text("Bought %s." % {buyText})
                    draw:space()
                    draw:hint("- Press [ENTER] to continue.")
                    
                    if self:enter() or self:cancel() then self:set("stage", "item input") end
                end
            end
            
            
            -- Sell Inventory
            
            if self:get("inventoryPurpose") == "sell" then
                
                -- Input
                
                if self:get("inspect stage") == "input" then
                    self:quantity(
                        player:numOfItem(item),
                        function() self:set("inspect stage", "output") end,
                        function() self:set("stage", "item select") end
                    )
                
                -- Output
                
                elseif self:get("inspect stage") == "output" then
                    local sellText = ""
                    if self:get("quantity") == 1 and not item:get("stackable") then sellText = item:display()
                    else sellText = item:display(self:get("quantity")) end
                    
                    local sellValue = math.ceil(item:get("value") * self:get("quantity") * 0.67)
                    sellText = sellText.." for <gp>{gp} {white}%d" % {sellValue}
                    
                    draw:space()
                    draw:text("Sold %s." % {sellText})
                    draw:space()
                    draw:hint("- Press [ENTER] to continue.")
                    
                    if self:enter() or self:cancel() then
                        player:removeItem(item, self:get("quantity"))
                        player:add("gp", sellValue)
                        
                        if player:numOfItem(item) == 0 or not item:get("stackable") then self:set("stage", "item input")
                        else self:set("inspect stage", "input") end
                    end
                end
            end
            
            
            -- Select Inventory
            
            if self:get("inventoryPurpose") == "select" then
                draw:space()
                if self:get("inspect stage") == "input" then
                    self:quantity(
                        player:numOfItem(item),
                        function() self:set("inspect stage", "output") end,
                        function() self:set("stage", "item select") end
                    )
                
                -- Output
                
                elseif self:get("inspect stage") == "output" then
                    self:up()
                end
            end
            
            
            -- Craft Inventory
            
            if self:get("inventoryPurpose") == "craft" then
                
                -- Display ingredients and determine max craft
        
                local craftable = true
                local numCraftable = 99999999
                local recipe = newRecipe(item:get("name"))
                draw:space()
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
                
                
                -- Input
                
                if self:get("inspect stage") == "input" then
                    self:quantity(
                        numCraftable,
                        function() self:set("inspect stage", "output") end,
                        function() up() end
                    )
                
                
                -- Output
                
                elseif self:get("inspect stage") == "output" then
                    draw:space()
                    draw:text("Crafted %s." % item:display())
                    
                    draw:space()
                    draw:hint("- Press [ENTER] to continue.")
                    
                    if self:enter() or self:cancel() then
                        for k, v in pairs(recipe:get("ingredients")) do
                            player:removeItem(k, v * self:get("quantity"))
                        end
                        player:addItem(newItem(item), self:get("quantity"))
                        
                        self:up()
                    end
                end
            end
            
            
            -- Main Inventory
            
            if self:get("inventoryPurpose") == "inventory" then
                
                -- Input
                
                if self:get("inspect stage") == "input" and not self:get("battle") then
                    local options = {}
                    if self:get("itemType") ~= "character" then options = {"Discard"} end
                    
                    local use = item:get("consumable") or item:get("weapon")
                    if use then
                        table.insert(options, 1, "Use")
                    elseif item:get("equipment") then
                        if self:get("itemType") == "character" then table.insert(options, 1, "Unequip")
                        else table.insert(options, 1, "Equip") end
                    end
                    
                    draw:space()
                    local option = input:options(options)
                    
                    if option == "e" and item:get("equipment") then
                        player:equip(item)
                        self:set("inspect stage", "equip")
                    elseif option == "u" and use then
                        for k, v in ipairs(item:get("effect")) do
                            appendTable(self:get("text"), v:use(item, player, player))
                        end
                        if not item:get("infinite") then player:removeItem(item) end
                        
                        self:set("inspect stage", "use")
                    elseif option == "u" and self:get("itemType") == "character" then
                        player:unequip(item)
                        self:set("inspect stage", "unequip")
                    elseif option == "d" then
                        if item:get("stackable") then
                            self:set("inspect stage", "discard")
                        else
                            player:removeItem(item)
                            self:set("quantity", 0)
                            
                            self:set("inspect stage", "discard output")
                        end
                    elseif option == "escape" then self:set("stage", "item input") end
                
                
                -- Input (Battle)
                
                elseif self:get("inspect stage") == "input" and self:get("battle") then
                    local options = {}
                    
                    local use = item:get("consumable") or item:get("weapon")
                    if use then
                        table.insert(options, 1, "Use")
                    elseif item:get("equipment") then
                        if self:get("itemType") == "character" then table.insert(options, 1, "Unequip")
                        else table.insert(options, 1, "Equip") end
                    end
                    
                    draw:space()
                    local option = input:options(options)
                    
                    if option == "e" and item:get("equipment") then
                        player:equip(item)
                        self:set("inspect stage", "equip")
                    elseif option == "u" and use then
                        self:up()
                        self:set("itemChosen", true)
                        self:set("item", item)
                        self:set("stage", "target")
                        
                        if item:get("targetSelf") and item:get("targetOther") then self:set("targetType", "all")
                        elseif item:get("targetSelf") then self:set("targetType", "self")
                        elseif item:get("targetOther") then self:set("targetType", "enemy") end
                    elseif option == "u" and self:get("itemType") == "character" then
                        player:unequip(item)
                        self:set("inspect stage", "unequip")
                    elseif option == "escape" then self:set("stage", "item input") end
                
                
                -- Equip Output
                
                elseif self:get("inspect stage") == "equip" then
                    draw:space()
                    draw:text("Equipped "..item:display()..".")
                    draw:space()
                    draw:hint("- Press [ENTER] to continue.")
                    
                    if self:cancel() or self:enter() then
                        if self:get("battle") then
                            self:up()
                            self:set("stage", "update")
                        else
                            self:set("stage", "item input")
                        end
                    end
                
                
                -- Unequip Output
                
                elseif self:get("inspect stage") == "unequip" then
                    draw:space()
                    draw:text("Unequipped "..item:display()..".")
                    draw:space()
                    draw:hint("- Press [ENTER] to continue.")
                    
                    if self:cancel() or self:enter() then
                        if self:get("battle") then
                            self:up()
                            self:set("stage", "update")
                        else
                            self:set("stage", "item input")
                        end
                    end
                
                
                -- Use Output
                
                elseif self:get("inspect stage") == "use" then
                    draw:space()
                    for k, v in ipairs(self:get("text")) do draw:text(v) end
                    
                    draw:space()
                    draw:hint("- Press [ENTER] to continue.")
                    
                    if self:cancel() or self:enter() then self:set("inspect stage", "output") end
                
                
                -- Discard Quantity
                
                elseif self:get("inspect stage") == "discard" then
                    self:quantity(
                        player:numOfItem(item),
                        function() self:set("inspect stage", "discard output") end,
                        function() self:set("inspect stage", "input") end
                    )
                
                
                -- Discard Output
                
                elseif self:get("inspect stage") == "discard output" then
                    local discardText = ""
                    if quantity == 1 then discardText = item:display()
                    else discardText = item:display(self:get("quantity"))  end
                    
                    draw:space()
                    draw:text("Discarded %s." % {discardText})
                    draw:space()
                    draw:hint("- Press [ENTER] to continue.")
                    
                    if self:cancel() or self:enter() then
                        player:removeItem(item, self:get("quantity"))
                        self:set("inspect stage", "output")
                    end
                
                
                -- Decide whether to go up or stay
                
                elseif self:get("inspect stage") == "output" then
                    if self:get("battle") then
                        self:up()
                    elseif player:numOfItem(item) == 0 or not item:get("stackable") then
                        self:set("stage", "item input")
                        self:set("index", 0)
                    else
                        self:set("text", {})
                        self:set("inspect stage", "input")
                    end
                end
            end
        end
    end,
    
    battle = function(self)
        
        -- Draw enemy info
        
        local left = draw.screenWidth - 50
        
        draw:reset(left, 0)
        draw.autoSpace = false
        draw:setColor(color.gray2)
        draw:rectangle("fill", 0, 0, draw.screenWidth - left - 2, draw.screenHeight)
        draw:setColor(color.gray15)
        draw:rectangle("fill", 0, 0, draw.screenWidth - left - 2, 3)
        draw:setColor(color.black)
        draw:rectangle("line", 0, -1, draw.screenWidth - left - 2, draw.screenHeight + 2)
        draw.autoSpace = true
        
        draw:shift()
        draw:space()
        draw:setColor()
        draw:text("Enemies")
        draw:text("-------")
        draw:space()
        
        for k, v in ipairs(self:get("enemy")) do
            v:set("targetID", string.sub("ABCDEFGHI", k, k))
            draw:hpmp(v, "%", 20)
            draw:space(2)
        end
        
        
        -- Draw player info
        
        draw:reset()
        draw:text("-= Battle =-")
        
        draw:space()
        draw:hpmp(player, "#", 20)
        draw:space()
        
        
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
            draw:reset(1, 7)
            for k, v in pairs(self:get("text")) do draw:text(v) end
            draw:space()
            draw:hint("- Press [ENTER] to continue.")
            if self:enter() or self:cancel() then
                if self:get("escape") then self:up()
                else self:set("stage", "update") end
            end
        
        
        -- Player's Turn
        
        elseif self:get("turnOrder")[self:get("turn")] == "player" then
            
            -- Choose action
            
            if self:get("stage") == "input" then
                self:set("text", {})
                
                draw:shift()
                local option = input:options({"Melee", "Guard", "Item", "Concede"})
                
                draw:space()
                if input:textButton("- Mouse over or hold [F1] for help.", 0, 0, color.gray4, color.gray4, color.gray4) == "hovered" or input.keyboard.f1.pressed then
                    draw:reset(15, 7)
                    draw:setColor("gray4")
                    draw:text("- Attack the enemy with your weapon.")
                    draw:space()
                    draw:text("- Concede your attack for defending against an enemy.")
                    draw:space()
                    draw:text("- (Un)equip or use an item.")
                    draw:space()
                    draw:text("- Concede from the battle. More or higher level enemies make this harder.")
                end
                
                if option == "m" then
                    self:set("targetType", "enemy")
                    self:set("stage", "target")
                elseif option == "g" then
                    player:set("guard", "block")
                    self:set("text", {player:display().." raises their guard."})
                    self:set("stage", "output")
                elseif option == "i" then
                    self:down("inventory")
                    self:set("battle", true)
                elseif option == "c" then
                    local meanLevel = 0
                    for k, v in ipairs(self:get("enemy")) do meanLevel = meanLevel + v:get("level") end
                    meanLevel = meanLevel / #self:get("enemy")
                    
                    local concedeChance = 84 - math.ceil(meanLevel - player:get("level")) * 2 - #self:get("enemy") * 2
                    
                    if rand(1, 100) <= concedeChance then
                        self:set("text", {player:display().." successfully conceded the battle!"})
                        self:set("escape", true)
                        self:set("stage", "output")
                    else
                        self:set("text", {player:display().." failed to concede the battle."})
                        self:set("stage", "output")
                    end
                end
            
            
            -- Choose target
            
            elseif self:get("stage") == "target" then
                local targets = {}
                local target = nil
                
                
                -- Draw target options
                
                draw:shift()
                
                local options = {}
                if self:get("targetType") ~= "enemy" then options = {"Self"} end
                for k, v in ipairs(self:get("enemy")) do
                    if v:get("hp") > 0 then
                        table.insert(options, v:display())
                        table.insert(targets, v)
                    end
                end
                
                local option, index = input:optionsList(options, self:get("index"))
                self:set("index", index)
                
                draw:space()
                draw:hint("- Press [UP] / [DOWN] to select an option.")
                
                if self:get("targetType") == "enemy" and #targets == 1 then option = "1" end
                if self:get("targetType") == "self" then option = "1" end
                
                
                -- Input
                
                if option == "escape" then self:set("stage", "input")
                elseif option ~= "" then
                    if self:get("targetType") == "all" then
                        if option == "1" then target = player
                        else target = targets[tonumber(option) - 1] end
                    else
                        target = targets[tonumber(option)]
                    end
                end
                
                
                -- Do damage based off of selected option
                
                if target ~= nil then
                    if self:get("itemChosen") then
                        for k, v in ipairs(self:get("item"):get("effect")) do
                            appendTable(self:get("text"), v:use(self:get("item"), player, target))
                        end
                        
                        if not self:get("item"):get("infinite") then player:removeItem(self:get("item")) end
                        
                        self:set("itemChosen", false)
                    else
                        appendTable(self:get("text"), player:attack(target))
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
        
        draw:reset()
        draw:text("-= Victory =-")
        
        draw:space()
        draw:hpmp(player)
        
        draw:space()
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
            
            hp = math.floor(player:get("stats").maxHp * 0.33)
            mp = math.floor(player:get("stats").maxMp * 0.33)
            
            if hp > player:get("hp") then player:set("hp", hp) end
            if mp > player:get("mp") then player:set("mp", mp) end
            
            self:set("stage", "output")
        
        
        -- Show drops
        
        elseif self:get("stage") == "output" then
            draw:space()
            draw:text("Obtained:")
            draw:text(" GP: <gp> "..lootEntity.gp)
            draw:text(" XP: <xp> "..lootEntity.xp)
            
            if #lootEntity:get("inventory") > 0 then
                draw:space()
                draw:text(" Items:")
                for k, v in ipairs(lootEntity:get("inventory")) do
                    local item = ""
                    if v[1]:get("stackable") then item = v[1]:display(v[2])
                    else item = v[1]:display() end
                    
                    draw:text(" - "..item)
                end
            end
            
            draw:space()
            draw:hint("- Press [ENTER] to continue.")
            
            if self:cancel() or self:enter() then self:upPast("battle") end
        end
    end,
    
    defeat = function(self)
        
        -- Draw
        
        draw:reset()
        draw:text("-= Defeat =-")
        
        draw:space()
        draw:hpmp(player)
        
        draw:space()
        draw:text("You lost!")
        
        draw:space()
        draw:text("The sound of oars treading water draws near.")
        draw:text("Charon agrees to return you to life.")
        draw:text("You feel... weakened.")
        
        
        -- Apply Charon's Curse
        
        if self:get("stage") == "curse" then
            player:set("hp", math.floor(player:get("stats").maxHp * 0.5))
            player:set("mp", math.floor(player:get("stats").maxMp * 0.5))
            player:applyPassive(newEffect("Charon's Curse"))
            self:set("stage", "input")
        
        
        -- Wait
        
        elseif self:get("stage") == "input" then
            draw:space()
            draw:hint("- Press [ENTER] to continue.")
            
            if self:cancel() or self:enter() then self:upPast("battle") end
        end
    end,
    
    options = function(self)
        draw:reset()
        draw:text("-= Options =-")
        
        draw:space()
        draw:options({"Audio", "Video", "Binds", "Misc"})
        
        if self:cancel() then self:up() end
    end,
    
	stats = function(self)
		draw:reset()
		draw:text("-= Stats =-")
        
        draw:space()
        draw:mainStats(player)
		
		draw:space()
        draw:shift()
		for k, v in ipairs(stats) do
			local stat = player:get("stats")[v]
			local baseStat = player:get("baseStats")[v]
			
			draw:text(title(v)..":")
			draw:space(-1)
			draw:text(rjust("%s (+ %s)" % {stat, stat - baseStat}, 40))
		end
		
        draw:space()
        draw:hint("- Press [ENTER] to continue.")
		if self:cancel() or self:enter() then self:up() end
	end,
	
    quit = function(self)
        
        -- Draw
        
        draw:reset()
        draw:text("-= Quit =-")
        
        draw:space()
        draw:text("Save before you quit?")
        
        draw:space()
        local option = input:options({"Yes", "No"})
        
        draw:space()
        
        
        -- Input
        
        if option == "y" then
            love.filesystem.write(player:get("name"), TSerial.pack(world:export(), false, true))
            os.exit()
        elseif option == "n" then
            os.exit()
        elseif option == "escape" then
            self:up()
            return true
        end
    end
}