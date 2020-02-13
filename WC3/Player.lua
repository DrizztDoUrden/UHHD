local Class = Require("Class")

local WCPlayer = Class()
local players = {}

function WCPlayer.Get(player)
    if math.type(player) == "integer" then
        player = Player(player)
    end
    if not players[player] then
        players[player] = WCPlayer(player)
    end
    return players[player]
end

function WCPlayer:ctor(player)
    self.handle = player
end

function WCPlayer:IsEnemy(other)
    if not other:IsA(WCPlayer) then
        error("Expected player as an argument", 2)
    end
    return IsPlayerEnemy(self.handle, other.handle)
end

function WCPlayer:SetTechLevel(tech, value)
    SetPlayerTechResearched(self.handle, tech, value)
end

WCPlayer.Local = WCPlayer.Get(GetLocalPlayer())

return WCPlayer