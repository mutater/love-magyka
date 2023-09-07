require "script/node"
require "script/tools"

local json = require("library/json")

local recipes = {}
for _, result in ipairs(getNamesFromDatabase("Recipe")) do
	local recipe = newRecipe(result)
    for name, quantity in pairs(recipe.ingredients) do
        if recipes[name] == nil then recipes[name] = {} end
        
        table.insert(recipes[name], recipe)
    end
end


-- Misc Functions

function setupString(arg, t) -- Loads an item from a table from the database
	local obj = nil
    local query = db:prepare("select * from %s where info_name=\"%s\"" % {t, arg})
    for row in query:nrows() do obj = row end
	
	for k, v in pairs(obj) do
		local key = split(k, "_")
		
		if #key > 1 then
			if obj[key[1]] == nil then obj[key[1]] = {} end
			
			obj[key[1]][key[2]] = v
			
			obj[k] = nil
		end
	end
	
    return obj
end

function setupTable(arg) -- Automatically formats as much of the table from the database as possible
	for k, v in pairs(arg) do
		if type(v) == "function" then goto continue end
        
		if v == "true" then arg[k] = true
        elseif v == "false" then arg[k] = false
		else arg[k] = decode(v) end
		
		::continue::
    end
	
    if arg.tags then
        for k, v in pairs(arg.tags) do arg[k] = v end
    end
    
	if arg.nodes then
		for _, node in ipairs(arg.nodes) do
			local newNode = _G["new"..node]
			local key = lowerFirst(node)
			
			if hasKey(arg, key) then arg[key] = newNode(arg[key])
			else arg[key] = newNode(_G[node]()) end
		end
	end
	
    return deepcopy(arg)
end

function createNode(arg, nodeIdentifier) -- Creates a node with information provided or with information from the database
	local nodeBase = _G[nodeIdentifier]
	local newNode = _G["new"..nodeIdentifier]
	local node = nil
	
	if type(arg) == "string" then node = setupTable(nodeBase(setupString(arg, nodeIdentifier)))
	elseif type(arg) == "table" then node = setupTable(nodeBase(arg))
	elseif arg == nil then node = setupTable(nodeBase()) end
	
	return node
end

function decode(obj) -- Formats object if object is string else returns original object
	if type(obj) == "string" then
		if pcall(json.decode, obj) then return json.decode(obj)
		else return obj end
    else return obj end
end


-- Object Generators

function newAlignment(arg)
    local alignment = createNode(arg, "Alignment")
	
	alignment:update()
	
	return alignment
end

function newArt(arg)
	local art = createNode(art, "Art")
	
	art:update()
	
	return art
	
	-- -- Automagic type and target bools
	
	-- if art.type == "passive" then
		-- art.battle = false
		-- art.targetSelf = false
		-- art.targetOther = false
	-- elseif art.type == "stance" then
		-- art.battle = true
		-- art.targetSelf = true
		-- art.targetOther = false
	-- elseif art.type == "restoration" then
		-- art.targetSelf = true
		-- art.targetOther = false
	-- elseif art.type == "destruction" then
		-- art.targetSelf = false
		-- art.targetOther = true
	-- elseif art.type == "degrade" then
		-- art.targetSelf = false
		-- art.targetOther = true
	-- elseif art.type == "alter" then
		-- art.targetSelf = false
		-- art.targetOther = false
	-- end
end

function newArts(arg)
    local arts = createNode(arg, "Arts")
	
	for k, v in ipairs(arts.list) do
		arts.list[k] = newArt(v)
	end
	
	arts:update()
	
	return arts
end

function newClass(arg)
	local class = createNode(arg, "Class")
	
	return class
end

function newEffect(arg)
	local effect = createNode(arg, "Effect")
	
	return effect
end

function newEffects(arg)
	local effects = createNode(arg, "Effects")
	
	for k, v in ipairs(effects.list) do
		effects.list[k] = newEffect(v)
	end
	
	return effects
end

function newEntity(arg) -- TODO: FIGURE OUT WHERE COMMENTED SEGMENTS GO (ERGO, ENEMY GENERATION)
	local entity = createNode(arg, "Entity")
	
	if entity.attackEffect then entity.attackEffect = newEffect(entity.attackEffect)
	else entity.attackEffect = newEffect({health={-1, -1}}) end
	
	entity:init()
	entity:update()
	
	return entity
	
	-- if entity.enemy then
		-- if entity.stats then
			-- entity.stats = json.decode(entity.stats)
			-- entity.baseStats = entity.stats
		-- end
	-- end

	-- Parse drops for enemies
	
	-- if entity.drops then entity.drops = newLoot(json.decode(entity.drops)) end
end

function newEquipment(arg)
	local equipment = createNode(arg, "Equipment")
	
	for k, v in pairs(equipment.list) do
		equipment.list[k] = newItem(v)
	end
	
	equipment:init()
	equipment:update()
	
	return equipment
end

function newHealth(arg)
    local health = createNode(arg, "Health")
	
	return health
end

function newInfo(arg)
	local info = createNode(arg, "Info")
	
	if type(info.description) == "string" then
		info.description = split(info.description, "\13\n")
	end
	
	return info
end

function newInventory(arg)
	local inventory = createNode(arg, "Inventory")
	
	for k, v in ipairs(inventory.list) do
		inventory.list[k] = newItem(v)
	end
	
	inventory:update()
end

function newItem(arg)
    local item = createNode(arg, "Item")
	
	item:init()
	item:update()
	
	return item
end

function newLevel(arg)
	local level = createNode(arg, "Level")
	
	return level
end

function newLoot(arg)
    local loot = createNode(arg, "Loot")
	
	for k, v in ipairs(loot.items) do
		loot.items[k] = newItem(v)
	end
	
	for k, v in ipairs(loot.arts) do
		loot.arts[k] = newArt(v)
	end
	
	return loot
end

function newLoots(arg)
	local loots = createNode(arg, "Loots")
	
	for k, v in ipairs(loots.list) do
		loots.list[k] = newLoot(v)
	end
	
	return loots
end

function newMana(arg)
    local mana = createNode(arg, "Mana")
	
	return mana
end

function newPassive(arg)
	local passive = createNode(arg, "Passive")
	
	return passive
end

function newPassiveHolder(arg)
	local passiveHolder = createNode(arg, "PassiveHolder")
	
	for k, v in ipairs(passiveHolder.list) do
		passiveHolder.list[k] = newPassive(v)
	end
	
	return passiveHolder
end

function newPassives(arg)
	local passives = createNode(arg, "Passives")
	
	for k, v in ipairs(passives.list) do
		passives.list[k] = newPassive(v)
	end
	
	return passives
end

function newRecipe(arg)
    local recipe = createNode(arg, "Recipe")
	
	recipe.result = newItem(recipe.result)
	
	return recipe
end

function newRecipes(arg)
	local recipes = createNode(arg, "Recipes")
	
	for k, v in ipairs(recipes.list) do
		recipes.list[k] = newRecipe(v)
	end
	
	return recipes
end

function newStatEffect(arg)
	local statEffect = createNode(arg, "StatEffect")
	
	statEffect:init()
	
	return statEffect
end

function newStats(arg)
	local arg = arg
	
	if not hasKey(arg, "base") then arg = {base=arg} end
	
	local stats = createNode(arg, "Stats")
	
	stats:init()
	
	return stats
end

function newStore(arg, town)
    if type(arg) == "string" then
        local store = newStore(require("data/town")[town]["stores"][arg])
        
        if store.items then
            for k, v in pairs(store.items) do store.items[k] = newItem(v) end
        end
        
        if store then return store else return Store{} end
    elseif type(arg) == "table" then
        local store = deepcopy(arg)
        
        if store.items then
            for k, v in pairs(store.items) do store.items[k] = newItem(v) end
        end
        
        return Store(store)
    end
end

function newTown(arg)
    local town = createNode(arg, "Town")
	
	return town
end

function newUsage(arg)
    local usage = createNode(arg, "Usage")
	
	return usage
end

function newWorld(arg)
    world = setupTable(arg)
    
    if world.player then world.player = createNode(world.player, "Entity")
    else world.player = createNode({info=newInfo{name="Player"}}, "Entity") end
	
    return World(world)
end