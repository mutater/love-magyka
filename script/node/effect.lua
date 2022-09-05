require "script/globals"
require "script/node/node"
require "script/tools"

Effect = Node{
    name = "effect",
    description = "",
    color = "white",
    hp = nil,
    mp = nil,
    hpCost = nil,
    mpCost = nil,
    crit = nil,
    critBonus = 0,
    critDamage = nil,
    critDamageBonus = 0,
    hit = nil,
    hitBonus = 0,
    noDodge = false,
    amount = 1,
    target = "entity",
    verb = "casts",
    preposition = "on",
    
    -- Arts
    
    art = false,
    useAttack = false,
    
    -- Passives
    
    passive = false,
    text = "",
    turns = 1,
    chance = 100,
    stats = nil,
    buff = true,
    passiveType = "",
    
    display = function(self)
        return self:get("name")
    end,
    
    use = function(self, parent, source, target)
        target = target or source
        local text = {}
        
        if self.target == "entity" then
            for i = 1, self.amount do
                if self.hpCost and parent:get("hp") then parent:add("hp", -self.hpCost) end
                if self.mpCost and parent:get("mp") then parent:add("mp", -self.mpCost) end
                
                local effect = {hp=0, mp=0}
                
                -- Hit and Dodge
                if source ~= target then
                    local hit = source:get("stats").hit + self.hitBonus
                    local dodge = target:get("stats").dodge
                    
                    if self.hit then hit = self.hit end
                    if self.noDodge then dodge = 0 end
                    
                    if rand(1, 100) <= 100 - hit then effect.miss = true
                    elseif rand(1, 100) <= dodge then effect.dodge = true end
                    
                    if effect.miss or effect.dodge then
                        table.insert(text, self:getTextEntity(parent, source, target, effect))
                        break
                    end
                end
                
                -- Hp and Mp damage
                if self.hp then effect.hp = rand(self.hp) end
                if self.mp then effect.mp = rand(self.mp) end
                
                if effect.hp < 0 or effect.mp < 0 then
                    local variance = rand(80, 120) / 100
                    local critMultiplier = 1
                    
                    local crit = source:get("stats").crit + self.critBonus
                    if self.crit then crit = self.crit end
                    crit = crit - target:get("stats").resistance
                    
                    if rand(1, 100) <= crit then
                        local critDamage = source:get("stats").critDamage + self.critDamageBonus
                        if self.critDamage then critDamage = self.critDamage end
                        
                        critMultiplier = critDamage / 100 + 1
                        effect.crit = true
                    end
                    
                    if effect.hp < 0 then
                        effect.hp = effect.hp + (target:get("stats").armor / 2) + target:get("stats").vitality
                        effect.hp = math.floor(effect.hp * critMultiplier * variance)
                        if effect.hp > 0 then effect.hp = 0 end
                    end
                    
                    if effect.mp < 0 then
                        effect.mp = effect.mp + target:get("stats").vitality
                        effect.mp = math.floor(effect.mp * critMultiplier * variance)
                        if effect.mp > 0 then effect.mp = 0 end
                    end
                end
                
                -- Passives
                if self.passive then
                    effect.passive = {}
                    for k, v in ipairs(self.passive) do
                        if rand(1, 100) <= v:get("chance") then
                            target:applyPassive(v)
                            table.insert(effect.passive, v:get("text"))
                        end
                    end
                end
                
                table.insert(text, self:getTextEntity(parent, source, target, effect))
                
                target:add("hp", effect.hp)
                target:add("mp", effect.mp)
            end
        end
        
        return text
    end,
    
    getTextEntity = function(self, parent, source, target, effect)
        local actionLine = ""
        local statusLine = ""
        local effectLine = ""
        local passiveLine = ""
        
        local effectBool = true
        local effectTypes = {}
        local effectTotal = 0
        local effectPercent = 0
        local effectAdjective = ""
        local effectVerb = ""
        local effectPunctuation = "."
        
        -- Action Line
        local verb = self:get("verb")
        local preposition = self:get("preposition")
        
        if parent and parent.verb then verb = parent.verb end
        if parent and parent.preposition then preposition = parent.preposition end
        
        actionLine = "%s %s" % {source:display(), verb}
        
        if source == target then actionLine = actionLine.." %s." % parent:display()
        else actionLine = actionLine.."." end
        
        -- Status Line
        if effect.crit then statusLine = statusLine.." %s crits!" % source:display() end
        if effect.miss then statusLine = statusLine.." %s misses." % source:display() end
        if effect.dodge then statusLine = statusLine.." %s dodges." % target:display() end
        if effect.block then statusLine = statusLine.." %s blocks." % target:display() end
        if effect.parry then statusLine = statusLine.." %s parries." % target:display() end
        --if effect.parry and effect.riposte then statusLine = statusLine.." %s parries and ripostes." % target:display() end
        
        -- Effect Line
        for k, v in pairs(effect) do
            if type(v) == "number" then
                table.insert(effectTypes, "<%s>" % k) 
                effectTotal = effectTotal + v
            end
        end
        
        if effectTotal < 0 then
            effectPercent = math.ceil(effectTotal / target:get("hp") * 100)
            effectVerb = "damaged"
        elseif effectTotal == 0 then
            
        else
            effectPercent = math.ceil(effectTotal / target:get("stats").maxHp * 100)
            effectVerb = "healed"
        end
        
        if not effect.miss and not effect.dodge and effectTotal ~= 0 then
            effectLine = " "
            effectPercent = math.abs(effectPercent)
            
            if effectPercent <= 2 then effectAdjective = "slightly"
            elseif effectPercent <= 5 then effectAdjective = "minorly"
            elseif effectPercent <= 10 then effectAdjective = "decently"
            elseif effectPercent <= 20 then effectAdjective = "moderately"
            elseif effectPercent <= 30 then effectAdjective = "significantly"
            elseif effectPercent <= 40 then effectAdjective = "severely"
            else effectAdjective = "immensely" end
            
            if effectPercent >= 30 then effectPunctuation = "!" end
            
            effectLine = effectLine..target:display()
            
            if effectTotal < 0 and target:get("hp") + effect.hp <= 0 then
                effectLine = effectLine.." is dead!"
            elseif effectTotal > 0 and target:get("hp") + effect.hp >= target:get("stats").maxHp then
                effectLine = effectLine.." is healed!"
            elseif effectTotal ~= 0 then
                effectLine = effectLine.." was %s %s%s" % {effectAdjective, effectVerb, effectPunctuation}
            end
        end
        
        -- Passive Line
        if effect.passive and #effect.passive > 0 then
            passiveLine = " %s" % target:display()
            for k, v in ipairs(effect.passive) do
                local passiveVerb = ""
                
                passiveLine = passiveLine.." %s" % v
                
                if k < #effect.passive then passiveLine = passiveLine.." &"
                else passiveLine = passiveLine.."." end
            end
        end
        
        -- Output
        local line = "%s%s%s%s" % {actionLine, statusLine, effectLine, passiveLine}
        return line
    end,
}