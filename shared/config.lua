Config = {}

-- DEBUG --
Config.Debug = true

Config.FuelExport = 'LegacyFuel'

Config.Shops = {
    ["pdm"] = {
        ["isFreeUse"] = true, -- free or owned
        ["shopZone"] = {
            vector3( -35.08, -1108.44, 26.42),
            vector3( -31.47, -1095.08, 26.42),
            vector3( -56.73, -1086.23, 26.42),
            vector3( -60.59, -1096.77, 26.42),
            vector3( -58.27, -1100.58, 26.42)
        },
        ["purchaseSpawn"] = vector4( -30.89, -1089.38, 26.01, 341.13),
        ['debugZone'] = false,
        ['job'] = 'cardealer',
        ['blipLabel'] = 'PDM',
        ['showBlip'] = true,
        ['blipSprite'] = 326, -- Blip sprite
        ['blipColor'] = 3,
        ['blipLocation'] = vector3( -41.16, -1099.44, 26.42),
        ['vehicles'] = {
            [1] = {
                coords = vector4( -40.2, -1095.28, 26.01, 159.12),
                default = 'adder',
                selected = 'adder',
                vehicleType = 'automobile', -- needs to be consistent for all types of categories (aka cars needs automobile, boats needs boat, etc.) more things about it here https://docs.fivem.net/natives/?_0x6AE51D4B
                categories = {
                    ['sedans'] = 'Sedans',
                    ['coupes'] = 'Coupes',
                    ['muscle'] = 'Muscle',
                    ['compacts'] = 'Compacts',
                    ['sports'] = 'Sports',
                }
            },
            [2] = {
                coords = vector4( -46.81, -1102.16, 25.77, 27.25),
                default = 'bati',
                selected = 'bati',
                vehicleType = 'bike', -- needs to be consistent for all types of categories (aka cars needs automobile, boats needs boat, etc.) more things about it here https://docs.fivem.net/natives/?_0x6AE51D4B
                categories = {
                    ['motorcycles'] = 'Motorcycles',
                }
            },
            [3] = {
                coords = vector4( -48.44, -1094.03, 26.01, 204.11),
                default = 'adder',
                selected = 'adder',
                vehicleType = 'automobile', -- needs to be consistent for all types of categories (aka cars needs automobile, boats needs boat, etc.) more things about it here https://docs.fivem.net/natives/?_0x6AE51D4B
                categories = {
                    ['sedans'] = 'Sedans',
                    ['coupes'] = 'Coupes',
                }
            },
        }
    }
}
