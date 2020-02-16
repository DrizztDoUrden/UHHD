local Class = require("Class")
local Timer = require("WC3.Timer")

local WCPlayer = Class()
local players = {}
local playersCount = 12
local isEnd = false

function WCPlayer.Get(player)
    if math.type(player) == "integer" then
        player = Player(player)
    end
    if not players[player] then
        players[player] = WCPlayer(player)
    end
    return players[player]
end


function WCPlayer.PlayersRemoweWithResult(isAVictory)
    local result = nil
    if isAVictory then
        result = PLAYER_GAME_RESULT_VICTORY
    else
        result = PLAYER_GAME_RESULT_DEFEAT
    end
    local tplayer = {}
    for id = 0, playersCount, 1  do
        local player = WCPlayer.Get(id)
        tplayer[id] = player
    end
    for id = 0, playersCount, 1  do
        tplayer[id]:RemovePlayer(result)
    end
    EndGame(true)
end

function WCPlayer.PlayersEndGame(isAVictory)
    local timer = Timer()
    if not isEnd then
        isEnd = true
        if isAVictory then
            WCPlayer.DisplayTextToAll("VICTORY")
        else
            WCPlayer.DisplayTextToAll("DEFEAT")
        end
        timer:Start(10, false, function()
            EndGame()
        end)
    end
end

function  WCPlayer.DisplayTextToAll(text)
    for id = 0, 23, 1 do
        DisplayTextToPlayer(WCPlayer.Get(id).handle, 0, 0, text)
    end
end

function WCPlayer:DisplayText(text)
    DisplayTextToPlayer(self.handle, 0, 0, text)
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

function WCPlayer:SetTechLevel(tech, value)
    SetPlayerTechResearched(self.handle, tech, value)
end

WCPlayer.Local = WCPlayer.Get(GetLocalPlayer())

return WCPlayer