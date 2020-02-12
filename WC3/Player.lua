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

function WCPlayer.IsActive(player)
    if math.type(player) == "integer" then
        player = Player(player)
    end
    if players[player] then
        return true
    else
        return false
    end
end


function WCPlayer.PlayersWin(playersCount)
    local tplayer = {}
    for id = 1, playersCount + 1, 1  do
        local player = WCPlayer.Get(id)
        tplayer[id] = player
    end
    for id = 1, playersCount + 1, 1  do
        tplayer[id]:RemovePlayer(PLAYER_GAME_RESULT_VICTORY)
    end
    EndGame()
end

function WCPlayer.PlayersLossing(playersCount)
    local tplayer = {}
    for id = 1, playersCount + 1 , 1 do
        local player = WCPlayer.Get(id)
        tplayer[id] = player
    end
    for id = 1, playersCount + 1, 1 do
        tplayer[id]:RemovePlayer(PLAYER_GAME_RESULT_DEFEAT)
    end
    EndGame()
end


function  WCPlayer:RemovePlayer(playerGameResult)
    RemovePlayer(self.handle, playerGameResult)
    players[self.handle] = nil
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

return WCPlayer