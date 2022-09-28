
-- Equipment Slots

equipment = {
    "weapon",
    "head",
    "body",
    "hands",
    "legs",
    "feet",
    "ring",
    "acc",
}

-- Item Types

itemTypes = {
    "weapon",
    "apparel",
    "consumable",
    "potion",
    "food",
    "material",
    "misc",
}


-- Displayed Stats

stats = {
    "maxHp",
    "maxMp",
    "strength",
    "intelligence",
    "dexterity",
    "vitality",
    "armor",
    "resistance",
    "hit",
    "dodge",
    "crit",
    "critDamage",
    "carry",
    "luck",
}


-- Hidden Stats

extraStats = {
    "hpRegen",
    "mpRegen",
    "xpGain",
    "gpGain",
    "itemGain",
    "block",
    "parry",
    "deflect",
}


-- Elements

elements = {
    "light",
    "night",
    "fire",
    "earth",
    "air",
    "water",
}


-- Add elemental resistance and damage to extraStats

for k, v in ipairs(elements) do
    table.insert(extraStats, v.."Damage")
    table.insert(extraStats, v.."Resistance")
end