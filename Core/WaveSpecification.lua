local Log = require("Log")

    local waveComposition = { 
        [1] = {{
            count = 4,
            unit = "Ghoul",
            ability = nil
        }},
        [2] = {{
            count = 5,
            unit = "Ghoul",
            ability = nil
        }},
        [3] = {{
            count = 5,
            unit = "MagicDragon",
            ability = nil
        }},
        [4] = {{
            count = 2,
            unit = "Ghoul",
            ability = nil
        },
        {
            count = 3,
            unit = "MagicDragon",
            ability = nil
        }},
        [5] = {{
            count = 5,
            unit = "Necromant",
            ability = nil
        }},
        [6] = {{
            count = 5,
            unit = "Necromant",
            ability = nil
        }},
        [7] = {{
            count = 5,
            unit = "Faceless",
            ability = nil
        }},
        [8] = {{
            count = 3,
            unit = "Faceless",
            ability = nil
        },{
            count = 3,
            unit = "Necromant",
            ability = nil
        }},
        [9] = {{
            count = 2,
            unit = "Faceless",
            ability = nil
        },
        {
            count = 2,
            unit = "Ghoul",
            ability = nil
        },{
            count = 2,
            unit = "Necromant",
            ability = nil
        },{
            count = 3,
            unit = "MagicDragon",
            ability = nil
        }},
        [10] = {{
            count = 1,
            unit = "DefiledTree",
            ability = nil
        }},
    }
Log("WaveSpecification is load")
return waveComposition