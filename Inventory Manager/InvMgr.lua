

---@class BusOutput
---@field public splitter ComponentReference
---@field public busName string
---@field public outputID number
---@field public stock StockPile
local BusOutput = {}


---@class StockPile
---@field public resource string
---@field public amount number
---@field public reservedAmount number
---@field public store ComponentReference
---@field public busses table<string,BusOutput>
---@field public orders LinkedList
---@field public reserved table<number, number>
---@field public noCraft boolean
---@field public outputs
---@field public autoCraftMaintain
---@field public hallIndex
local StockPile = {}


json = filesystem.doFile("/json.lua")

---@type table<string,StockPile>
local stock = {
}

local fluidTypes = getFluidTypes()

---@type table<string,Actor>
local containerCache = {}

local lastLowStock = 0
local LOW_STOCK_TIMEOUT = 60000

local inventoryPanelResourceMap = {}
function updateResource(resource)
    local obj = inventoryPanelResourceMap[resource.resource]
    if obj ~= nil then
        if obj.update == nil then
            printArray(obj, 5)
            error()
        end
        obj:update(resource)
    end
end



function buildStorageCache()
    local all = component.findComponent("");
    for _,id in pairs(all) do
        local comp = component.proxy(id)
        local name = comp.nick
        local p = explode("_", name)
        --if p[1] ~= nil and p[1] == "Store" and p[2] ~= nil and p[3] ~= nil then
        --    print(p[1] .. " : " .. p[2] .. " : " ..p[3])
        --end
        if p[1] == "Store" and p[3] == scriptInfo.hallName then
            containerCache[p[2]] = comp
        end
    end
    --printArray(containerCache, 1)
end

function findStorage(resource, pile)
    if containerCache[resource] then
        if pile then
            local name = containerCache[resource].nick
            local p = explode("_", name)
            pile.store = createReference(containerCache[resource].id)
            pile.hallIndex = tonumber(p[4])
            if p[5] ~= nil then
                pile.autoCraftMaintain = tonumber(p[5])
            end
        end
        return true
    end
    return false

    --local all = component.findComponent("");
    --for _,id in pairs(all) do
    --    local comp = component.proxy(id)
    --    local name = comp.nick
    --    local p = explode("_", name)
    --    --if p[1] ~= nil and p[1] == "Store" and p[2] ~= nil and p[3] ~= nil then
    --    --    print(p[1] .. " : " .. p[2] .. " : " ..p[3])
    --    --end
    --    if p[1] == "Store" and p[2] == resource and p[3] == scriptInfo.hallName then
    --        if pile then
    --            pile.store = comp
    --            pile.hallIndex = tonumber(p[4])
    --            if p[5] ~= nil then
    --                pile.autoCraftMaintain = tonumber(p[5])
    --            end
    --        end
    --        return true
    --    end
    --end
    --rerror("Cannot find storage container for " .. resource)
    --return false
end


---@class StockSource
---@field public splitter ComponentReference
---@field public busses table<string>
---@field public servesBusses string
---@field public stock StockPile
local StockSource = {}

---@param id string
---@return StockSource
function StockSource.new(id)
    ---@type StockSource
    local obj = {
        busses = {},
        splitter = createReference(id),
        servesBusses = "",
        stock = nil,
    }
    setmetatable(obj, StockSource)
    StockSource.__index = StockSource
    return obj;
end

function StockSource:onItem()
    local orderItem = self.stock.orders.first
    computer.skip()
    --print("Meow")
    if orderItem ~= nil and orderItem.value ~= nil then
        ---@type QueueOrder
        local order = orderItem.value
        if self.busses[order.output.busName] ~= nil and self.stock.amount > 0 then
            ---@type CodeableSplitter
            local splitter = self.splitter:get()
            --printArray(order, 1)
            --print("Transferring item " .. order.value.resource .. " to output " .. tostring(order.value.output.outputID))
            if splitter:transferItem(tonumber(order.output.outputID)) then
                computer.skip()
                order.amount = order.amount - 1
                self.stock.reservedAmount = self.stock.reservedAmount - 1
                self.stock.amount = self.stock.amount - 1
                if order.amount <= 0 then
                    orderItem:delete()
                    print("Ok, order removed" .. "Remaining reserved amount: " .. tostring(self.stock.reservedAmount))
                else
                    --print("Ok, " .. order.value.amount .. " remaining to output" .. "Remaining reserved amount: " .. tostring(self.stock.reservedAmount))
                end
            elseif splitter:getInput() == nil then
                --splitter:flush()
                --print("Failed, attempting flush")
            else
                --print("Failed to transfer "..order.value.resource .. " to " .. tostring(order.value.output.outputID))
            end
        end
    end
end

---@param busName string
---@param compID string
---@param outputID number
---@param stock StockPile
---@return BusOutput
function BusOutput.new(busName, compID, outputID, stockpile)
    ---@type BusOutput
    local obj = {
        busName = busName,
        splitter = createReference(compID),
        outputID = outputID,
        stock = stockpile
    }
    setmetatable(obj, BusOutput)
    BusOutput.__index = BusOutput
    return obj
end


function initStockOutputs()
    local all = component.findComponent("");
    for _,id in pairs(all) do
        local comp = component.proxy(id)
        local name = comp.nick
        local p = explode("_", name)
        if p[1] == "Source" then
            if findStorage(p[2]) then
                local lstock = getStock(p[2])
                local outputs = parseOutputs(p[3])
                local source = StockSource.new(comp.id)
                source.stock = lstock
                for bus,outputID in pairs(outputs) do
                    lstock.busses[bus] = BusOutput.new(bus, comp.id, tonumber(outputID), lstock)
                    --lstock.busses[bus] = {
                    --    splitter = createReference(comp.id),
                    --    busName = bus,
                    --    outputID = tonumber(outputID),
                    --    stock = lstock,
                    --}
                    source.busses[bus] = lstock.busses[bus]
                end
                registerEvent(comp, source,  source.onItem, nil, true)
                if source.onItem == nil then
                    printArray(source, 5)
                    error()
                end
                schedulePeriodicTask(PeriodicTask.new(source.onItem, source, nil, "Source Splitter onItem"))
                --periodicStuff:push({
                --    func = stockFunctions.outputOnItem,
                --    ref = source
                --})
            end
        end
    end
end

---@class QueueOrder
---@field public resource string
---@field public amount number
---@field public taskID number
---@field public output BusOutput
local QueueOrder = {}

---@param resource string
---@param amount number
---@param taskID number
---@param output BusOutput
---@return QueueOrder
function QueueOrder.new(resource, amount, taskID, output)
    ---@type QueueOrder
    local obj = {
        resource = resource,
        amount = amount,
        taskID = taskID,
        output = output
    }
    setmetatable(obj, QueueOrder)
    QueueOrder.__index = QueueOrder
    return obj
end


---@param amount number
---@param byBus string
---@param taskID number
function StockPile:order(amount, byBus, taskID)
    if self.busses[byBus] ~= nil then
        --print("Ordering " .. tostring(amount) .." of " .. self.resource .. " by bus " .. byBus)
        local order = QueueOrder.new(self.resource, amount, taskID, self.busses[byBus])
        --   resource = self.resource,
        --   amount = amount,
        --   taskID = taskID,
        --   output = self.busses[byBus]
        --}
        --printResource(stock[self.resource])
        if self.reserved[taskID] ~= nil then
            --print("  Previously reserved by task " .. tostring(taskID))
            rdebug("Reserve order exists for " .. tostring(self.reserved[taskID]) .. " units, removing")
            local adj = self.reserved[taskID] - amount
            if adj ~= 0 then
                rdebug("Adjusted reserved amount by " .. tostring(adj) .. " because reserved and ordered differs")
            end
            self.reservedAmount = self.reservedAmount - (adj)
            self.reserved[taskID] = nil
        else
            --print("  No reservation, quick reserve wihtout task")
            self.reservedAmount = self.reservedAmount + amount
        end
        -- print("  Total reserved in queue: " .. self.reservedAmount)
        --printResource(stock[self.resource])
        self.orders:push(order)
        return true
    else
        error("Bus " .. byBus .. " not served by " .. self.resource)
    end
    return false
end

---@param amount number
---@param taskID number
---@param forced boolean @If true, will reserve even if not enough stock, ensuring no craft order is sent out
function StockPile:reserve(amount, taskID, forced)
    local oldReserve = self.reservedAmount
    self.reservedAmount = self.reservedAmount + amount
    self.reserved[taskID] = amount
    printResource(stock[self.resource])
    if not self.noCraft and self.amount - oldReserve < amount and not forced == true then
        return math.max(0, self.amount - oldReserve)
    end
    return amount
end

function StockPile:onGet()
    self.amount = self.amount + 1
end

function StockPile:onLost()
    self.amount = self.amount - 1
end

---@param resource string
---@return StockPile
function StockPile.new(resource)
    ---@type StockPile
    local pile = {
        resource = resource,
        amount = 0,
        reservedAmount = 0,
        store = nil,
        busses = {},
        orders = LinkedList.new(QueueOrder),
        reserved = {},
        noCraft = false,
        outputs = {},
        onLost = nil,
        onGet = nil,
    }
    setmetatable(pile, StockPile)
    StockPile.__index = StockPile
    return pile
end


function getStock(resource)
    if fluidTypes[resource] ~= nil then
        resource = fluidTypes[resource].packaged
    end
    if stock[resource] == nil then
        print("getStock(".. resource .. ")")
        local pile = StockPile.new(resource)
        if findStorage(resource, pile) == false then
            error("Nil store for " .. pile.resource)
        end
        if pile.store == nil then
            error("Nil store for " .. pile.resource)
        end
        local store = pile.store:get()
        pile.amount = store:getInventories()[1].ItemCount
        --printArray(pile)
        local connectors = store:getFactoryConnectors()
        if connectors[1] and connectors[2] and connectors[3] and connectors[4] then
            registerEvent(connectors[2], pile, pile.onGet, nil, true)
            registerEvent(connectors[4], pile, pile.onGet, nil, true)
            --registerEvent(connectors[1], pile, pile.onLost, nil, true)
            --registerEvent(connectors[3], pile, pile.onLost, nil, true)
            --error("BREAK")
        elseif connectors[1] and connectors[2] then
            registerEvent(connectors[2], pile, pile.onGet, nil, true)
            --registerEvent(connectors[1], pile, pile.onLost, nil, true)
            --error("BREAK")
        end
        stock[resource] = pile
        return pile
    else
        return stock[resource]
    end
end

function initEmgPanel() 
	if scriptInfo.emgPanel then
	    print("Initializing emg panel: " .. scriptInfo.emgPanel)
		local panels = component.proxy(component.findComponent(scriptInfo.emgPanel))
		for _,k in pairs(panels) do
			local modules = k:getModules()
			local btnEmgStop = modules[1]
			
			--setCommandLabelText(k, 0, "", false)
			
			--k:setLabelIcon(0, "EmgStop", true)
			
			initModularButton(
				btnEmgStop, 
				function(trigger, params) 
					print("btnEmgStop:Click")
				end, 
				rgba(0.4, 0.0, 0.0, 0.0)
			,true)
		end
	end
end

local inventoryPanelFunctions


function initInvPanels()
    local panelName = scriptInfo.name .. "_Panel"
    local panels = component.findComponent(panelName)  --InvMgr_H1_Panel 2
    if #panels == 0 then
        error("No panels found by the name " .. panelName)
    end
    inventoryPanelData.panels = {}
    for _,panelName2 in pairs(panels) do
        local panel = component.proxy(panelName2)
        local _spl = explode(" ", panel.nick)
        local index = tonumber(_spl[2])
        inventoryPanelData.panels[index] = panel
        if panel == nil then
            error("Nil panel?")
        end
        for i = 0, 8 do
            local status = panel:getModule(0, i)
            local disp = panel:getModule(1, i)
            status:setColor(0,0,0,0)
            disp:setText(" ")
        end
    end
    for _,resourceItem in pairs(inventoryPanelData.resources) do
        print("Initializing " .. resourceItem.resource)
        local index = resourceItem.index - 1
        local panelIndex = math.floor(index / 9)
        local subIndex = index % 9
        resourceItem.panel = inventoryPanelData.panels[panelIndex]
        if resourceItem.panel == nil then
            error("Could not find panel " .. panelName .. " " .. tostring(panelIndex) .. "x" ..tostring(subIndex))
        end
        resourceItem.localIndex = subIndex
        resourceItem.display = resourceItem.panel:getModule(1, subIndex)
        resourceItem.status = resourceItem.panel:getModule(0, subIndex)
        if stackSize[resourceItem.resource] == nil then
            error("No stack size for " .. resourceItem.resource)
        end
        resourceItem.maxStock = stackSize[resourceItem.resource] * 40
        local lstock = stock[resourceItem.resource]
        inventoryPanelResourceMap[resourceItem.resource] = resourceItem
        if lstock ~= nil then
            lstock.updateResource = updateResource
            updateResource(lstock)
        else
            error("Stock for " .. resourceItem.resource .. " not found")
        end
    end
end

local lastUpdatedIndex = 1

function updateInventoryDisplay()
    --local resourceItem = inventoryPanelData.resources[lastUpdatedIndex]
    --if resourceItem ~= nil then
    --    local lstock = stock[resourceItem.resource]
    --    if lstock ~= nil then
    --        resourceItem:update(lstock)
    --    end
    --    computer.skip()
    --    lastUpdatedIndex = lastUpdatedIndex + 1
    --    if lastUpdatedIndex > #inventoryPanelData then
    --        lastUpdatedIndex = 1
    --    end
    --end
    for _,resourceItem in pairs(inventoryPanelData.resources) do
        local lstock = stock[resourceItem.resource]
        if lstock ~= nil then
            resourceItem:update(lstock)
        end
        computer.skip()
    end
end

function initAuxPanels()
	if scriptInfo.auxPanel then
	    print("Initializing aux panel: " .. scriptInfo.auxPanel)
		local panels = component.proxy(component.findComponent(scriptInfo.auxPanel))
		for _,k in pairs(panels) do
			print(" * Panel found: " .. k.id)
			
			local modules = k:getModules()
			printArray(modules, 1)
			
			local indError = modules[3]
			local btnEnable = modules[2]
			local btnDisable = modules[1]
			
			--setCommandLabelText(k, 2, "Error", false)
			--setCommandLabelText(k, 1, "Enable", false)
			--setCommandLabelText(k, 0, "Disable", false)
			
			indError:setColor(0.2, 0.1, 0.1, 0)
			initModularButton(
				btnEnable, 
				function(trigger, params)
					print("btnEnable:Click")
				end, 
				rgba(0, 1, 0.1, 0)
			)
			event.listen(btnEnable)
			initModularButton(
				btnDisable, 
				function(trigger, params) 
					print("btnDisable:Click")
				end, 
				rgba(1, 0, 0.1, 0)
			)
			event.listen(btnDisable)
			indError:setColor(1, 0, 0.05, 1)
		end
	end
end


function initTestPanel()
    if scriptInfo.hasPanel then
        local panel = component.proxy(component.findComponent("InvMgr_Panel")[1])

        local btnTest1 = panel:getModule(0, 10)

        print(btnTest1)
        registerEvent(btnTest1, nil, function()
            getStock("Raw Quartz"):order(1, "A", 1)
        end)
        event.listen(btnTest1)

        local btnTest2 = panel:getModule(3, 10)

        print(btnTest2)
        registerEvent(btnTest2, nil, function()
            getStock("Iron Ingot"):order(1, "B", 2)
        end)
        event.listen(btnTest2)
    end

end

---@class TopUpSource
---@field public reference ComponentReference
---@field public output number
---@field public stock StockPile
---@field public keep number
local TopUpSource = {}

---@param compID string
---@param output number
---@param resource string
---@param amount number
---@return TopUpSource
function TopUpSource.new(compID, output, resource, amount)
    ---@type TopUpSource
    local obj = {
        reference = createReference(compID),
        output = output,
        stock = getStock(resource),
        keep = amount
    }
    setmetatable(obj, TopUpSource)
    TopUpSource.__index = TopUpSource
    return obj
end

---@param comp2
---@param param
function TopUpSource:onItem(comp2, param)
    local reference = self.reference:get()
    local item = reference:getInput()
    --print("onItem()")
    --printArray(self);
    --print(item)
    if item then
        --print("Keep="..tostring(self.keep)..", has="..tostring(self.stock.amount))
        if self.stock.amount < self.keep then
            --print("Attempting trasfer...")
            local n = tonumber(self.output)
            if reference:getInput(n) then
                --print("Transferring to " .. n)
                reference:transferItem(n)
                return true
            else
                --error("To little items but cannot output? " .. self.stock.resource)
            end
        end
    elseif self.stock.amount < self.keep then
        --self.reference:flush()
    end
    return false
end

function initTopup()
    if scriptInfo.topupPrefix then
        local all = component.findComponent("");
        for _,id in pairs(all) do
            local comp = component.proxy(id)
            local name = comp.nick
            local p = explode("_", name)
            if p[1] == scriptInfo.topupPrefix then
                local resource = p[2]
                local outputs = parseOutputs(p[3])
                local amount = tonumber(p[4])
                local topUp = TopUpSource.new(comp.id, tonumber(outputs.O), resource, amount)
                --local topUp = {
                --    reference = createReference(comp.id),
                --    output = tonumber(outputs.O),
                --    stock = getStock(resource),
                --    keep = amount,
                --    onItem = stockFunctions.topupOnItem
                --}
                topUp.stock.noCraft = true
                local referece = topUp.reference:get()
                registerEvent(referece, topUp, topUp.onItem, nil, true)
                schedulePeriodicTask(PeriodicTask.new(topUp.onItem, topUp, nil, "Top Up onItem"))
                --periodicStuff:push({
                --    func = topUp.onItem,
                --    ref = topUp
                --})
                --print("Topup done: "..name)
            end
        end
    end
end

function initSources()

end


function initNetwork()
    networkHandler(106, nil, { -- table of message handlers
        ---@param parameters InvMgrOrderMsg
        order = function(address, parameters)
            --printArrayToFile("/lastOrder.txt", parameters)
            if parameters.taskID ~= nil then
                rmessage("Order by network, " .. parameters.count .. " " .. parameters.name .. " to " .. parameters.bus .. " [" .. parameters.taskID .. "]")
            else
                rmessage("Order by network, " .. parameters.count .. " " .. parameters.name .. " to " .. parameters.bus .. " [No Task]")
            end
            getStock(parameters.name):order(parameters.count, parameters.bus, parameters.taskID)
        end,
        ---@param parameters InvMgrReserveParams
        reserve = function(address, parameters)
            --print("Reserve by network")
            --printArray(parameters)
            local ret = getStock(parameters.name):reserve(parameters.count, parameters.taskID, parameters.forcedReserve)
            local rem = parameters.count - ret
            if parameters.recycle then
                local oldRem = rem
                rem = rem - parameters.recycle
                rdebug("   " .. tostring(oldRem) .. " missing items but order has " .. tostring(parameters.recycle) .. " recycleable items, so new missing is " .. tostring(rem))
            end
            if rem > 0 then
                --print("Send needs made")
                if fluidTypes[parameters.name] ~= nil then
                    parameters.name = fluidTypes[parameters.name].name
                end
                ---@type ProdMgrSubmitWorkMsg
                local data = {
                    name = parameters.name,
                    count = rem,
                    reserved = ret,
                    taskID = parameters.taskID
                }
                scriptInfo.network:send(scriptInfo.addresses.ProdMgr, 100, "submitWork", "json", json.encode(data))
            else
                --print("Send quantity ok")
                scriptInfo.network:send(scriptInfo.addresses.ProdMgr, 100, "dependencyFinished", "json", json.encode({
                    taskID = parameters.taskID,
                    name = parameters.name
                }))
            end
        end,
        requestStock = function(address, parameters)
            pushInfo(address)
        end,
        dumpInventory = function(address, parameters)
            printArrayToFile("stock.txt" , stock)
        end
    })
end

function printResource(resource)
    print(rpad(tostring(resource.hallIndex), 3, " ") .. rpad(resource.resource, 30, " ") .. ": has="..rpad(tostring(resource.amount), 6, " ") .. ", reserved=" .. rpad(tostring(resource.reservedAmount), 6, " ")..", noCraft=" ..tostring(resource.noCraft))
end

function writeResource(file, resource)
    file:write(rpad(tostring(resource.hallIndex), 3, " ") .. rpad(resource.resource, 30, " ") .. ": has="..rpad(tostring(resource.amount), 6, " ") .. ", reserved=" .. rpad(tostring(resource.reservedAmount), 6, " ")..", noCraft=" ..tostring(resource.noCraft) .. "\n")
end

function pushInfo(address)
    computer.skip()
    rdebug("Sending inventory to " .. address)
    local data = {
        stock = {},
        hallName = scriptInfo.hallName
    }
    local i = 0
    for _,r in pairs(stock) do
        computer.skip()
        data.stock[tostring(i)] = {
            name = r.resource,
            index = r.hallIndex,
            amount = r.amount,
            reserved = r.reservedAmount
        }
        i = i + 1
    end
    computer.skip()
    scriptInfo.network:send(address, 100, "inventory", "json", json.encode(data))
end

function periodicLowStock()
    local tick = computer.millis()
    if tick - lastLowStock > LOW_STOCK_TIMEOUT then
        checkLowStock()
        lastLowStock = tick;
    end
end

function initPeriodicLowStockCheck()
    schedulePeriodicTask(PeriodicTask.new(function() return periodicLowStock()  end, nil, 30000, "Low Stock Check"))
    --periodicStuff:push({
    --    func = function()
    --        return periodicLowStock()
    --    end,
    --    ref = nil,
    --})
end


function sortByRatio(a, b)
    return a.ratio < b.ratio
end

function checkLowStock()
    local missingItems = {}
    local count = 1
    for _,item in pairs(stock) do
        local maxStack = stackSize[item.resource]
        if maxStack == nil then
            error("No stack size for " .. item.resource)
        end
        local amount = item.amount - item.reservedAmount
        local maxStock = maxStack * 40
        local hasPercent = amount / maxStock
        if hasPercent < keepStockRatio then
            missingItems[count] = {
                name = item.resource,
                has = amount,
                maxStock = maxStock,
                keepRatio = keepStockRatio,
                ratio = hasPercent
            }
            count = count + 1
        end
    end
    printArrayToFile("missingStock.txt", missingItems)
    scriptInfo.network:send(scriptInfo.addresses.ProdMgr, 100, "lowStock", "json", json.encode(missingItems))
end

function main()

    --print("Meow")
--
    --error("Nyan")

    buildStorageCache()

    initNetwork()

    initTopup()

    initStockOutputs()

    initTestPanel()
	
	initEmgPanel()
	
	initAuxPanels()

    initInvPanels()

    checkLowStock()
    --if true then return true end

    pushInfo(scriptInfo.addresses.BusMgr)

    initPeriodicLowStockCheck()

    --printArray(stock.Coal, 2)

    rmessage("System Operational")

    local seldomCounter = 1000
    local periodicTask
    local counter = 0

    print( " -- - INIT DONE - - --  ")

    print("Stock for " .. scriptInfo.hallName .. ": ")
    local ordered = {}
    local highIndex = 0
    for _,resource in pairs(stock) do
        ordered[resource.hallIndex] = resource
        if resource.hallIndex > highIndex then
            highIndex = resource.hallIndex
        end
    end
    local resourceFile = filesystem.open("/Resources.txt", "w")
    for i = 1,highIndex,1 do
        computer.skip()
        local resource = ordered[i]
        if resource ~= nil then
            printResource(resource)
            writeResource(resourceFile, resource)
        end
    end
    resourceFile:close()

    print( " -- - STARTUP DONE - - --  ")

    schedulePeriodicTask(PeriodicTask.new(updateInventoryDisplay, nil, 1000, "Inventory Display Update"))

    commonMain(0.2, 0.05)

end