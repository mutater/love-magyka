require "script/globals"
require "script/node/node"
require "script/tools"

Effect = Node{
    identity = "Effect",
	nodes = {
		"Info",
		"Passives",
		"Alignment",
	},
    amount = nil,
    health = nil,
    mana = nil,
    healthCost = nil,
    manaCost = nil,
    crit = nil,
    critDamage = nil,
    hit = nil,
    noDodge = false,
    chance = 100,
    
    getHit = function(self, parent, source, target)
        if source ~= target then
            local hit = sources.stats.current.hit + self.hit
            return tert(rand(1, 100) <= 100 - hit, 1, 0)
        end
        
        return 1
    end,
    
    getDodge = function(self, parent, source, target)
        if source ~= target and noDodge == false then
            local dodge = target.stats.current.dodge
            return tert(rand(1, 100) <= dodge, 0, 1)
        end
        
        return 1
    end,
    
    getGuard = function(self, parent, source, target)
        if source ~= target then
            if target.guard == "block" then
                return 0
            elseif target.guard == "parry" then
                return 0
            elseif target.guard == "deflect" then
                return rand(33, 66) / 100
            end
        end
        
        return 1
    end,
    
    getCrit = function(self, parent, source, target)
        local crit = source.stats.current.crit + self.crit
        if source ~= target then crit = crit - target.stats.current.resistance end
        
        return tert(rand(1, 100) <= crit, source.stats.current.critDamage + self.critDamage, 1)
    end,
    
    getVariance = function(self, parent, source, target)
        return rand(80, 120) / 100
    end,
    
    getHealthDamage = function(self, parent, source, target, effect)
        local hp = rand(self.health)
        if hp < 0 then hp = hp + (target.stats.current.armor / 2) + target.stats.current.vitality end
        return self:getDamage(hp, effect)
    end,
    
    getManaDamage = function(self, parent, source, target, effect)
        local mp = rand(self.mana)
        if mp < 0 then mp = mp + target.stats.current.intelligence + target.stats.current.vitality end
        return self:getDamage(mp, effect)
    end,
    
    getDamage = function(self, damage, effect)
        return damage * effect.hit * effect.dodge * effect.guard * effect.crit * effect.variance
    end,
    
    activate = function(self, parent, source, target)
        target = target or source
        local text = {}
        local healthCost = 0
        local manaCost = 0
        
        for i = 1, self.amount do
            effect.hit = self:getHit(parent, source, target)
            effect.dodge = self:getDodge(parent, source, target)
            effect.guard = self:getGuard(parent, source, target)
            effect.crit = self:getCrit(parent, source, target)
            effect.variance = self:getVariance(parent, source, target)
            
            effect.health = self:getHealthDamage(parent, source, target, effect)
            effect.mana = self:getManaDamage(parent, source, target, effect)
            
            if self.healthCost and parent.health then healthCost = rand(self.healthCost) end
            if self.manaCost and parent.mana then manaCost = rand(self.manaCost) end
            
            if self.passives and target.passives then effect.passives = self.passives:activate(source, target) end
            
            target:add("hp", effect.hp)
            target:add("mp", effect.mp)
            
            appendTable(text, self:getText(parent, source, target, effect))
        end
        
        if healthCost ~= 0 then
            source.health:add(-healthCost)
            table.insert(text, self:getEffectLine(source, source.health, {health = -healthCost}))
        end
        
        if manaCost ~= 0 then
            source.mana:add(-manaCost)
            table.insert(text, self:getEffectLine(source, source.mana, {mana = -manaCost}))
        end
        
        return text
    end,
    
    getActionLine = function(self, parent, source, target)
        local verb = self.info.verb
        if parent.info then verb = parent.info.verb or verb end
        
        local preposition = self.info.preposition
        if parent.info then verb = parent.info.preposition or preposition end
        
        local line = "%s %s" % {source:display(), verb}
        
        if target == source then
            line = line.." %s." % parent:display()
        elseif preposition == nil then
            line = line.." %s." % target:display()
        else
            line = line.." %s %s %s." % {parent:display(), preposition, target:display()}
        end
        
        return line
    end,
    
    getStatusLine = function(self, source, target, effect)
        local line = ""
        
        if effect.crit > 1 then line = line.." %s crits!" % source:display() end
        if effect.hit == 0 then line = line.." %s misses." % source:display() end
        if effect.dodge == 0 then line = line.." %s dodges!" % source:display() end
        if effect.guard > 0 then
            if effect.guard == 1 then line = line.." %s blocks!" % source:display()
            else line = line.." %s deflects." % source:display() end
        end
        
        return line
    end,
    
    getEffectLine = function(self, target, stat, effect)
        local effectStat = effect[stat.identity:lower()]
        if effect.hit == 0 or effect.dodge == 0 or effectStat == 0 then return "" end
        
        local line = " "..target:display()
        
        -- If entity dies or is healed, skip cool stuff below
        
        if stat.identity == "Health" then
            if target.health.current <= 0 then
                return line.." is dead."
            elseif target.health.current >= target.health.maxx then
                return line.." is healed!"
            end
        elseif stat.identity == "Mana" then
            if target.mana.current <= 0 then
                return line.." is drained."
            elseif target.mana.current >= target.mana.max then
                return line.." is restored!"
            end
        end
        
        -- Percentage of damage and verb
        
        local percent = 0
        local verb = ""
        
        if effectStat <= 0 then
            percent = math.ceil(effectStat / stat.current * 100)
            verb = "damaged"
        else
            percent = math.ceil(effectStat / stat.max * 100)
            verb = "healed"
        end
        percent = math.abs(percent)
        
        -- Adjective
        
        if percent <= 2 then adjective = "slightly"
        elseif percent <= 5 then adjective = "minorly"
        elseif percent <= 10 then adjective = "decently"
        elseif percent <= 20 then adjective = "moderately"
        elseif percent <= 30 then adjective = "significantly"
        elseif percent <= 40 then adjective = "severely"
        else adjective = "immensely" end
        
        -- Punctuation
        
        local punctuation = tern(percent >= 20, "!", ".")
        
        return line.." was %s %s%s" % {adjective, verb, punctuation}
    end,
    
    getPassiveLine = function(self, target, effect)
        if effect.passive == nil or #effect.passive == 0 then return "" end
        
        local line = {}
        for k, v in ipairs(effect.passive) do
            table.insert(line, " %s %s" % {target:display(), v.info.verb, v:display()})
        end
        
        return line
    end,
    
    getText = function(self, parent, source, target, effect)
        local actionLine = self:getActionLine(parent, source, target)
        local statusLine = self:getStatusLine(source, target, effect)
        local healthEffectLine = self:getEffectLine(target, target.health, effect)
        local manaEffectLine = self:getEffectLine(target, target.mana, effect)
        local passiveLine = self:getPassiveLine(target, effect)
        
        if statusLine..effectLine..passiveLine == "" then statusLine = " %s is unaffected." % target:display() end
        
        local line = {}
        for k, v in ipairs({actionLine, statusLine, effectLine, passiveLine}) do
            if v ~= "" then table.insert(line, v) end
        end
        
        return line
    end,
}