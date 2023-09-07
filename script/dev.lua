local inspect = require "library/inspect"

devCommand = function(command)
    command = split(command, " ", 1)
    local word = command[1]
    local args = split(command[2], ", ")
    
    if word == "battle" then
        if args[1] then
            screen:down("battle")
            screen:set("enemy", {newEntity(args[1])}, "battle")
        end
    
    
    elseif word == "clear" then
        return "clear"
    
    
    elseif word == "quit" then
        os.exit()
    
    
    elseif word == "s" then
        world = newWorld{}
        player = world:get("player")
        player.info.name = "Developer"
        player:setClass(newClass("Warrior"))
        devCommand("give all")
        devCommand("art all")
        devCommand("pset gp, 999999999")
        saving = false
        screen:down("camp")
        
        return {"Started the game as Developer"}
    
    elseif word == "qs" then
        world = newWorld{}
        player = world:get("player")
        player:set("name", "Vincent")
        player:setClass(newClass("Warrior"))
        saving = false
        screen:down("camp")
        
        return {"Started the game as Vincent"}
    
    
    elseif word == "level" then
        local num = 1
        if args[1] then num = tonumber(args[1]) end
        if num == nil then return {"{red}Not a valid number."} end
        for i = 1, num do player:levelUp() end
        return {"Levelled up to level "..player:get("level")}
    
    
    elseif word == "equip" then
        if args[1] then
            local item = newItem(args[1])
            if item:get("type") == "equipment" then
                player:equip(item)
                return {"Equipped "..item:display()}
            else
                return {"{red}Item not found: {white}'%s'" % item:display()}
            end
        end
    
    
    elseif word == "give" then
        if args[1] then
            local quantity = 1
            if #args > 1 then quantity = tonumber(args[2]) end
            
            if args[1] == "all" then
                local names = getNamesFromDatabase("Item")
                for k, v in ipairs(names) do player:addItem(newItem(v), quantity) end
                return {"Gave all items in database"}
            else
                local item = newItem(args[1])
                player:addItem(item, quantity)
                return {"Gave item '%s'" % item:display()}
            end
        end
    
    
    elseif word == "art" then
        if args[1] then
            if args[1] == "all" then
                local names = getNamesFromDatabase("Art")
                for k, v in ipairs(names) do player:addArt(newArt(v)) end
                return {"Gave all arts in database"}
            else
                local art = newArt(args[1])
                player:addArt(art)
                return {"Gave art '%s'" % art:display()}
            end
        end
    
    
    elseif word == "heal" then
        player:set("hp", 999999999)
        player:set("mp", 999999999)
        return {"Healed the player"}
    
    
    elseif word == "stat" then
        if args[1] then
            local val = tonumber(args[2])
            if val == nil then val = args[2] end
            
            local t = player:get("baseStats")
            if t[args[1]] then t[args[1]] = val
            else return {"{red} Unable to set 'baseStats[%s]' in Player." % {args[1]}} end
            
            player:update()
            return {"Set variable 'baseStats[%s]' in Player to '%s'" % {args[1], val}}
        end
    
    
    elseif word == "sget" then
        print(dumpTable(screen[args[1]]))
        return {"Got variable '%s' from Screen" % args[1]}
    
    
    elseif word == "pget" then
		if hasFunction(player[args[1]], "print") then
			player[args[1]]:print()
        else
			print(dumpClass(player:get(args[1])))
		end
        return {"Got variable '%s' from Player" % args[1]}
    
    
    elseif word == "pset" then
        if #args == 2 then
            local val = tonumber(args[2])
            if val == nil then val = args[2] end
            
            player:set(args[1], val)
            return {"Set variable '%s' in Player to '%s'" % {args[1], val}}
        elseif #args == 3 then
            local val = tonumber(args[3])
            if val == nil then val = args[3] end
            
            local t = player:get(args[1])
            if t[args[2]] then t[args[2]] = val
            else return {"{red} Unable to set '%s[%s]' in Player." % {args[1], args[2]}} end
            
            return {"Set variable '%s[%s]' in Player to '%s'" % {args[1], args[2], val}}
        end
    
    
    elseif word == "itemInfo" then
        if args[1] then print(inspect(newItem(args[1]):export())) end
    end
end