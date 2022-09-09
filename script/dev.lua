devCommand = function(command)
    command = split(command, " ", 1)
    local word = command[1]
    local args = split(command[2], ", ")
    
    local player = world:get("player")
    
    if word == "battle" then
        if args[1] then
            screen:down("battle")
            screen:set("enemy", {newEntity(args[1])}, "battle")
        end
    
    
    elseif word == "equip" then
        if args[1] then
            player:equip(newItem(args[1]))
        end
    
    
    elseif word == "give" then
        if args[1] then
            local quantity = 1
            if #args > 1 then quantity = tonumber(args[2]) end
            
            player:addItem(newItem(args[1]), quantity)
        end
    
    
    elseif word == "heal" then
        player:set("hp", 999999999)
        player:set("mp", 999999999)
    
    
    elseif word == "sget" then
        print(dumpTable(screen[args[1]]))
    
    
    elseif word == "pget" then
        print(dumpTable(player:get(args[1])))
    
    
    elseif word == "pset" then
        if #args == 2 then
            local val = tonumber(args[2])
            if val == nil then val = args[2] end
            
            player:set(args[1], val)
        elseif #args == 3 then
            local val = tonumber(args[3])
            if val == nil then val = args[3] end
            
            local t = player:get(args[1])
            if t[args[2]] then t[args[2]] = val end
        end
    end
end