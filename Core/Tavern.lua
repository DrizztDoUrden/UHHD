local Class = require("Class")
local WC3 = require("WC3.All")
local Log = require("Log")
local Stats = require "Core.Stats"

local logTavern = Log.Category("Core\\Tavern")

local heroSpawnX = -2300
local heroSpawnY = -3400

local Tavern = Class(WC3.Unit)

function Tavern:ctor(owner, x, y, facing, heroPresets)
    WC3.Unit.ctor(self, owner, FourCC("n000"), x, y, facing)

    self.owner = owner
    self.heroPresets = heroPresets
    self:AddTrigger()
    WC3.Camera.PanTo(x, y)
    self:Select()
end

function Tavern:AddTrigger()
    local trigger = WC3.Trigger()
    self.toDestroy[trigger] = true
    trigger:RegisterUnitSold(self)
    trigger:AddAction(function()
        local buying = WC3.Unit.GetBying()
        local sold = WC3.Unit.GetSold()
        local owner = sold:GetOwner()
        local id = sold:GetTypeId()
        local hero
        logTavern:Trace("Unit bought with id ".. id)
        for _, preset in pairs(self.heroPresets) do
            if preset.unitid == id then
                hero = preset:Spawn(owner, heroSpawnX, heroSpawnY, 0)
                break
            end
        end
        buying:Destroy()
        sold:Destroy()
        WC3.Camera.PanTo(heroSpawnX, heroSpawnY, owner)
        if owner == WC3.Player.Local then
            ClearSelection()
            hero:Select()

            local statsMultiBoard = WC3.Multiboard()

            statsMultiBoard:SetTitleText("Secondary Stats")
            statsMultiBoard:SetSize(2, #Stats.Secondary.names)

            for i, name in hero.secondaryStats:EnumerateNames() do
                local meta = Stats.Secondary.meta[name]
                local nameItem = statsMultiBoard:GetItem(i - 1, 0)
                nameItem:SetValue(meta.display)
                nameItem:SetStyle({displayText = true})
                nameItem:SetWidth(0.12)
                nameItem:Release()
                local valueItem = statsMultiBoard:GetItem(i - 1, 1)
                valueItem:SetValue(meta.formatter(hero.secondaryStats[name]))
                valueItem:SetStyle({displayText = true})
                valueItem:SetWidth(0.06)
                valueItem:Release()
            end

            statsMultiBoard:SetVisibility(true)

            local function ValueUpdater()
                for i, name in hero.secondaryStats:EnumerateNames() do
                    local meta = Stats.Secondary.meta[name]
                    local valueItem = statsMultiBoard:GetItem(i - 1, 1)
                    valueItem:SetValue(meta.formatter(hero.secondaryStats[name]))
                    valueItem:Release()
                end
            end

            hero.onApplyStats[ValueUpdater] = true
        end
    end)
end

return Tavern