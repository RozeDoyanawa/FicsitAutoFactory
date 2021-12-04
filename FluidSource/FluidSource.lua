local periodicStuff = createLinkedList()


function clearInventories(manufacturer)
    for _,v in pairs(manufacturer:getInventories()) do
        v:flush()
    end
end




function initNetwork()
    networkHandler(100, null, { -- table of message handlers
    })
end

---@type FluidContainer[]
local containers = {}


function scheduler()
    for _, v in pairs(containers) do
        local container = v.container:get()
        local stock = container:getInventories()[1].ItemCount
        print(v.itemName .. " has " .. tostring(stock) .. "(" .. tostring(v.outstanding) .. ") and should be at " .. tostring(v.limit) )
        if  v.limit - stock - v.outstanding > v.treshold and v.outstanding < v.maxOutstanding then
            v.outstanding = v.outstanding + v.treshold
            print("Order " .. tostring(v.treshold) .. " " .. v.itemName)

            ---@type ProdMgrRequestToMsg
            local request = {
                name = v.itemName,
                count = v.treshold,
                bus = scriptInfo.puller
            }
            scriptInfo.network:send(scriptInfo.addresses.ProdMgr, 100, "requestTo", "json", json.encode(request))
        end
    end
end

---@class FluidContainer
---@field public itemName string
---@field public treshold number
---@field public limit number
---@field public container ComponentReference
---@field public maxOutstanding number
---@field public outstanding number
local FluidContainer = {}

---@param itemName string
---@param compID string
---@param treshold number
---@param limit number
---@param maxOutstanding number
---@return FluidContainer
function FluidContainer.new(itemName, compID, treshold, limit, maxOutstanding)
    ---@type FluidContainer
    local obj = {
        itemName = itemName,
        treshold = treshold,
        limit = limit,
        container = createReference(compID),
        maxOutstanding = maxOutstanding
    }
    setmetatable(obj, FluidContainer)
    FluidContainer.__index = FluidContainer
end

function FluidContainer:onItem()
    self.outstanding = outstanding - 1
end

function initContainers()
    local all = component.findComponent("");
    for _,id in pairs(all) do
        local comp = component.proxy(id)
        local cname = comp.nick
        local p = explode("_", cname)
        if p[1] == scriptInfo.containerPrefix then
            local itemName = p[2]
            local parameters = parseOutputs(p[3])
            print("Found container for ".. itemName)
            printArray(parameters)
            local treshold = parameters["T"]
            if treshold == nil then
                treshold = stackSize[itemName]
            end
            local fillTo = parameters["L"]
            local maxOutstanding = parameters["O"]
            if maxOutstanding == nil then
                maxOutstanding = treshold
            end

            local container = FluidContainer.new(itemName, comp.id, tonumber(treshold), tonumber(fillTo), tonumber(maxOutstanding))
            local container = {

                itemName = itemName,
                treshold = tonumber(treshold),
                limit = tonumber(fillTo),
                container = createReference(comp.id),
                maxOutstanding = tonumber(maxOutstanding),
                outstanding = 0,
                onItem = function(self)
                    self.outstanding = self.outstanding - 1
                end
            }

            local connector = comp:getFactoryConnectors()[tonumber(parameters["I"])]
            registerEvent(connector, container, container.onItem, nil, true)
            table.insert(containers, container)
        end

    end
end


function main()

    initNetwork()

    initContainers()

    --printArray(stock.Coal, 2)

    rmessage("Startup delay")

    wait(4000)

    rmessage("System Operational")

    schedulePeriodicTask(PeriodicTask.new(scheduler, nil, nil, "Fluid Scheduler"))

    print( " -- - INIT DONE - - --  ")

    for _, v in pairs(containers) do
        print(v.itemName .. " @ " .. tostring(v.limit))
    end

    print( " -- - STARTUP DONE - - --  ")

    commonMain(10, 1)

end