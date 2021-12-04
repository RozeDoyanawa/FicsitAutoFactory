json = filesystem.doFile("/json.lua")

---@type string[]
local components = {}

---@type table<string,string[]>
local componentNickData = {}


---@type table<string,BusStockpile>
local stockpiles = {

}

---@type table<string,BusStockpileResource>
local resources = {

}

local busCount = 0

local fluidTypes = getFluidTypes()

---@class BusSplitter
---@field public name string
---@field public requester ComponentReference
---@field public queue LinkedList<BusQueueItem>
---@field public parent BusSplitter
---@field public inQueue number
---@field public root boolean
---@field public outputs table<string,string>
local BusSplitter = {}


---@type table<string,BusSplitter>
local allPullers = {}

---@type table<string,BusSplitter>
allPullers = {}

function initComponentCache()
    components = component.findComponent("");
    componentNickData = {}
    for k,v in pairs(components) do
        local comp = component.proxy(v)
        componentNickData[k] = explode("_", comp.nick)
    end
end

---@param itemName string
---@param itemCount number
---@param taskID number
function BusSplitter:order(itemName, itemCount, taskID)
    if self.root then
        if fluidTypes[itemName] ~= nil then
        itemName = fluidTypes[itemName].packaged
        end
        if resources[itemName] then
            --printArray(resources[itemName], 1)
            rmessage("Sending request for " .. itemCount .. " " .. itemName .. " from " .. resources[itemName].stockpile.address)
            ---@type InvMgrOrderMsg
            local data = {
                name = itemName,
                count = itemCount,
                taskID = taskID,
                bus = self.name
            }
            scriptInfo.network:send(resources[itemName].stockpile.address, 106, "order", "json", json.encode(data))
            else
            rerror("No stockpile for " .. itemName)
        end
    else
        computer.skip()
        if taskID ~= nil then
            print("order(" .. self.name .. ", " ..itemName .. ", " ..itemCount .. " [" .. taskID .. "])")
        else
            print("order(" .. self.name .. ", " ..itemName .. ", " ..itemCount .. " [No Task])")
        end
        ---@type BusQueueItem
        local value = {
            name = itemName,
            amount = tonumber(itemCount),
            taskID = taskID,
        }
        self.queue:push(value)
        self.inQueue = self.inQueue + itemCount
        if self.parent == nil then
            --printArray(self, 1)
        end
        self.parent:order(itemName, itemCount, taskID)
        computer.skip()
    end
end

---@return boolean
function BusSplitter:onItem()
    computer.skip()
    --print("Checking " .. self.name)
    local f = self.queue.first
    local requester = self.requester:get()
    local item = requester:getInput()
    if item.type ~= nil then
        while f ~= nil do
            if f.value.name == item.type.name then
                --print("Item("..f.value.name..") needed by " .. self.name .. ", transfer to " .. self.outputs.L)
                if requester:transferItem(tonumber(self.outputs.L)) then
                    f.value.amount = f.value.amount - 1
                    self.inQueue = self.inQueue - 1
                    --print("Remaining " .. tostring(f.value.amount) .. " of " .. f.value.name)
                    if f.value.amount <= 0 then
                        f:delete()
                    end
                else
                    print("Transfer failed at "..self.name)
                end
                computer.skip()
                return true
            end
            f = f.next
        end
        --print(item)
        --print(item.type)
        --print(self.name)
        --print("Item("..item.type.name..") passed on by " .. self.name .. ", transfer to " .. self.outputs.B)
        requester:transferItem(tonumber(self.outputs.B))
        computer.skip()
        return true
    end
    computer.skip()
    return false
end

---@param name string
---@return BusSplitter
function BusSplitter.new(name, parent, root)
    if root == nil then
        root = false
    end
    ---@type BusSplitter
    local obj = {
        name = name,
        queue = createLinkedList(),
        requester = nil,
        parent = nil,
        inQueue = 0,
        parent = parent,
        root = root
    }
    if not root then
        obj.requester = findPullerComponent(name)
    end
    setmetatable(obj, BusSplitter)
    BusSplitter.__index = BusSplitter
    return obj
end

---@param name string
---@return BusSplitter
function getBus(name)
    if allPullers[name] then
        --print("getBus("..name..")");
        return allPullers[name]
    else
        --print("getBus(*NEW*"..name..")");
        local bus = BusSplitter.new(name)
        --local bus = {
        --    name = name,
        --    requester = findPullerComponent(name),
        --    queue = createLinkedList(),
        --    parent = nil,
        --    inQueue = 0,
        --    onItem = busFunctions.onItem,
        --    order = busFunctions.order
        --}
        local busRef = bus.requester:get()

        allPullers[name] = bus
        busCount = busCount + 1
        local p = explode("_", busRef.nick)
        local pparent = p[3]
        ---@type table<string, string>
        local outputs
        if p[4] then
            outputs = parseOutputs(p[4])
        else
            error("Missing output information on puller " .. name)
        end
        bus.outputs = outputs;
        bus.parent = getBus(pparent)

        --printArray(bus, 1)
        registerEvent(busRef, bus, bus.onItem, nil, true);
        schedulePeriodicTask(PeriodicTask.new(bus.onItem, bus))
        --periodicStuff:push({
        --    func = bus.onItem,
        --    ref = bus
        --})
        return bus
    end
end


---@return ComponentReference
function findPullerComponent(name)
    computer.skip()
    for k,p in pairs(componentNickData) do
        if p[1] == "Bus" and p[2] == name then
            --print("Found puller: "..comp.nick)
            return createReference(components[k])
        end
        computer.skip()
    end

    --for _,id in pairs(components) do
    --    local comp = component.proxy(id)
    --    local cname = comp.nick
    --    local p = explode("_", cname)
    --    if p[1] == "Bus" and p[2] == name then
    --        --print("Found puller: "..comp.nick)
    --        return createReference(comp.id)
    --    end
    --end
    error("Could not find puller " .. name)
    return nil
end

function initBusPullers()
    computer.skip()
    for _,p in pairs(componentNickData) do
        if p[1] == "Bus" then
            getBus(p[2])
        end
        computer.skip()
    end
    rmessage("Initialized " .. tostring(busCount) .. " bus pullers")

    --local all = components;
    --for _,id in pairs(all) do
    --    if p[1] == "Bus" then
    --        getBus(p[2])
    --    end
    --end
end


function initNetwork()
    if scriptInfo.network then
        scriptInfo.network:open(100)
        event.listen(scriptInfo.network)
    else
        print ("No such adapter")
    end
    networkHandler(100, nil, { -- table of message handlers
        ---@param parameters BusMgrOrderParams
        order = function(address, parameters)
            rmessage("Order by network " .. parameters.count .. " " .. parameters.name .. " from " .. parameters.bus )
            if allPullers[parameters.bus] then
                allPullers[parameters.bus]:order(parameters.name, parameters.count, parameters.taskID )
            else
                rerror("Bus " .. parameters.bus.. " not found" )
            end

            --printArray(parameters)
        end,
        ---@param parameters BusMgrReserveParams
        reserve = function(address, parameters)
            rmessage("Reserve by network " .. parameters.count .. " " .. parameters.name )
            local name = parameters.name
            if fluidTypes[name] ~= nil then
                name = fluidTypes[name].packaged
                parameters.name = name
            end
            if resources[name] then
                scriptInfo.network:send(resources[name].stockpile.address, 106, "reserve", "json", json.encode(parameters) )
            else
                rerror("Resource '" .. parameters.name .. "' not found in stockpile register")
            end
            --printArray(parameters)
        end,
        balancedOrder = function(address, parameters)

            --printArray(parameters)
        end,
        inventory = function(address, parameters)
            computer.skip()
            local stockpile
            if stockpiles[parameters.hallName] == nil then
                ---@type BusStockpile
                stockpile = {
                    name = parameters.hallName,
                    address = address
                }
                stockpiles[stockpile.name] = stockpile
            else
                stockpile = stockpiles[parameters.hallName]
            end
            local count = 0
            for _,r in pairs(parameters.stock) do
                computer.skip()
                ---@type BusStockpileResource
                resources[r.name] = {
                    name = r.name,
                    stockpile = stockpile
                }
                count = count + 1
            end
            --local file = filesystem.open("/inv." .. address .. ".txt", "w")
            --file:write(json.encode(parameters))
            --file:close()
            rmessage("Received " .. count .. " resources from " .. address)
        end
    })
    scriptInfo.network:broadcast(106, "requestStock")
end


function main()

    initComponentCache()

    allPullers["A"] = BusSplitter.new("A", nil, true)
    allPullers["B"] = BusSplitter.new("B", nil, true)
    allPullers["C"] = BusSplitter.new("C", nil, true)

    initBusPullers()

    initNetwork()

    printArray(allPullers.C, 2)

    rmessage("System Operational")


    print( " -- - INIT DONE - - --  ")


    commonMain(0.2, 0.01)

end