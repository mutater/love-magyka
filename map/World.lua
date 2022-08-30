return {
    portals = {
        {
            name = "Town",
            town = true,
            x = 111,
            y = 101,
        },
        {
            name = "Dungeon",
            teleport = true,
            x = 114,
            y = 112,
            targetX = 17,
            targetY = 28,
        },
    },
    encounters = {
        [5] = {
            "Brown Slime",
            "Green Slime",
        },
        [10] = {
            "Gray Slime",
            "Blue Slime",
        },
        [15] = {
            "Purple Slime",
            "Orange Slime",
        },
    },
}