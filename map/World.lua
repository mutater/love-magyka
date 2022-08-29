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
            x = 111,
            y = 111,
            targetX = 23,
            targetY = 26,
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