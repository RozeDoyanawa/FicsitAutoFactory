
keepStockRatio = 0.3

---@class InventoryPanelResource
---@field public resource string
---@field public index number
---@field public maxStock number
---@field public localIndex number
---@field public display MicroDisplayModule
---@field public status IndicatorModule
InventoryPanelResource = {}


---@class InventoryPanelData
---@field public resources InventoryPanelResource[]
---@field public panels Actor[]
InventoryPanelData = {}

---@param resource string
---@param index number
---@return InventoryPanelResource
function InventoryPanelResource.new(resource, index)
    ---@type InventoryPanelResource
    local obj = {
        resource = resource,
        index = index,
        maxStock = 0,
        localIndex = 0,
        display = nil,
        status = nil,
    }
    setmetatable(obj, InventoryPanelResource)
    InventoryPanelResource.__index = InventoryPanelResource
    return obj
end

function InventoryPanelResource:update(resource)
    if self.display ~= nil and self.status ~= nil then
        if resource.reservedAmount > 0 then
            self.display:setText(tostring(resource.amount) .. "\n" .. resource.reservedAmount)
            self.display:setColor(0.5, 0.5, 0, 0.4)
        else
            self.display:setText(tostring(resource.amount))
            self.display:setColor(0, 0.5, 0, 0.4)
        end
        local sum = resource.amount - resource.reservedAmount
        local p = sum / self.maxStock
        if p <= 0 then
            self:setEmpty(self)
        elseif p >= 1 then
            self:setFull(self)
        elseif p < keepStockRatio then
            self:setLow(self)
        else
            self:setOK(self)
        end
    end
end

local STATUS_INDICATOR_ALPHA = 0.5

function InventoryPanelResource:setOK()
    self.status:setColor(0, 1, 0, STATUS_INDICATOR_ALPHA)
end
function InventoryPanelResource:setFull()
    self.status:setColor(1, 0.3, 0, STATUS_INDICATOR_ALPHA)
end
function InventoryPanelResource:setLow()
    self.status:setColor(1, 1, 0, STATUS_INDICATOR_ALPHA)
end
function InventoryPanelResource:setEmpty()
    self.status:setColor(1, 0, 0.01, STATUS_INDICATOR_ALPHA)
end

