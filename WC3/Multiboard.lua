local Class = require "Class"

local Multiboard = Class()

local MultiboardItem = Class()

function Multiboard:ctor()
    self.handle = CreateMultiboard()
end

function Multiboard:Destroy()
    DestroyMultiboard(self.handle)
    self.handle = nil
end

function Multiboard:Clear()
    MultiboardClear(self.handle)
end

function Multiboard:SetVisibility(value)
    MultiboardDisplay(self.handle, value)
end

function Multiboard:Minimize(value)
    MultiboardMinimize(self.handle, value)
end

function Multiboard:SetRowCount(value)
    MultiboardSetRowCount(self.handle, value)
end

function Multiboard:SetColumnCount(value)
    MultiboardSetColumnCount(self.handle, value)
end

function Multiboard:SetSize(width, height)
    self:SetColumnCount(width)
    self:SetRowCount(height)
end

function Multiboard:GetItem(x, y)
    return MultiboardItem(self, x, y)
end

function Multiboard:SetTitleText(value)
    MultiboardSetTitleText(self.handle, value)
end

function Multiboard:SetTitleTextColor(color)
    MultiboardSetTitleText(self.handle, math.floor(color.r * 255), math.floor(color.g * 255), math.floor(color.b * 255), math.floor((color.a or 1) * 255))
end

--[[ MultiboardItem: ]]

function MultiboardItem:ctor(multiboard, x, y)
    self.handle = MultiboardGetItem(multiboard.handle, x, y)
end

function MultiboardItem:Release()
    MultiboardReleaseItem(self.handle)
    self.handle = nil
end

function MultiboardItem:SetValue(value)
    MultiboardSetItemValue(self.handle, value)
end

function MultiboardItem:SetStyle(style)
    MultiboardSetItemStyle(self.handle, style.displayText or false, style.displayImage or false)
end

function MultiboardItem:SetWidth(value)
    MultiboardSetItemWidth(self.handle, value)
end

return Multiboard