

local periodicStuff = createLinkedList()


---@param item BusMgrOrderParams
function requestItem(item)
    rmessage("Requesting " .. item.count .. " " .. item.name .. " from " .. item.bus)
    scriptInfo.network:send(scriptInfo.addresses.BusMgr, 100, "order", "json", json.encode(item))
end

---@param factory CraftUnitFactory
function reportFinishedTask(factory)
    ---@type ProdMgrFinishedTask
    local data = {
        taskID = factory.taskID,
        factoryIndex = factory.index
    }
    scriptInfo.network:send(scriptInfo.addresses.ProdMgr, 100, "finishedTask", "json", json.encode(data))
end


function clearInventories(manufacturer)
    for _,v in pairs(manufacturer:getInventories()) do
        v:flush()
    end
end

function getPeriodicStuff()
    return periodicStuff
end

function pushInfo(address)
    if address == nil then
        address = scriptInfo.addresses.ProdMgr
    end
    for _,unit in pairs(craftUnits) do
        printArray(unit, 2)
        ---@type CraftUnitInfo
        local data = {
            craftUnit = unit.unitInfo.name,
            comment = unit.unitInfo.comment,
            factoryCount = unit.factoryCount,
            recipes = unit.recipes,
            makers = {}
        }
        --scriptInfo.network:send(address, 100, "craftUnitData", "json", json.encode(data))
        --for _,recipe in pairs(recipes) do
        --scriptInfo.network:send(address, 100, "recipeData", "json", json.encode(recipe))
        --end

        computer.skip()
        for _,maker in pairs(unit.factories) do
            computer.skip()
            ---@type CraftUnitMakerData
            local makerData = {
                index = maker.makerIndex,
                status = maker.status
            }
            data.makers[maker.makerIndex] = makerData
            --scriptInfo.network:send(address, 100, "makerData", "json", json.encode(makerData))
        end
        scriptInfo.network:send(address, 100, "allMakerData", "json", json.encode(data))
        print("Sending maker infor to " .. address)
    end
end


function initNetwork()
    networkHandler(105, function(self, address, parameters, parameterOffset)  -- Initiate handler for port 100
        local msg = parameters[parameterOffset] -- extract message identifier
        print(msg)
        printArray(parameters, 2)
        if msg and self.subhandlers[msg] then  -- if msg is not nil and we have a subhandler for it
            local handler = self.subhandlers[msg] -- put subhandler into local variable for convenience
            computer.skip()
            if parameters[parameterOffset + 1] == "json" then
                parameters = json.decode(parameters[parameterOffset + 2])
                handler(address, parameters, nil) -- call subhandler
            else
                handler(address, parameters, parameterOffset + 1) -- call subhandler
            end
            computer.skip()
        elseif not msg then -- no handler or nil message
            print ("No message identifier defined")
        else
            print ("No handler for " .. parameters[parameterOffset])
        end
    end, { -- table of message handlers
        submitMakeOrder = function(address, parameters)
            local factories = getFactories()
            local factory = factories[parameters.index]
            if factory ~= nil then
                if factory:make(parameters.recipeName, parameters.count, parameters.taskID, parameters.target) ~= true then
                    error("Attempt to make at busy factory " .. parameters.index)
                end
            end
        end,
        pushMakerInfo = function(address, parameters)
            print("Request to push maker data to " .. address)
            pushInfo(address)
        end
    })
end



function main()

    factoryCount = initFactories()

    initNetwork()

    pushInfo(nil, factories, factoryCount, recipes)

    --printArray(stock.Coal, 2)

    rmessage("System Operational")

    local seldomCounter = 1000
    local periodicTask
    local counter = 0

    print( " -- - INIT DONE - - --  ")

    print("Factories found: ")

    for _,maker in pairs(getFactories()) do
        computer.skip()
        local sources = ""
        if maker.sources ~= nil then
            for _,source in pairs(maker.sources) do
                computer.skip()
                if string.len(sources) > 0 then
                    sources = sources .. " + "
                end
                sources = sources .. source
            end
        else
            sources = maker.source .. " + " .. maker.unpackerSource .. " + " .. maker.packerSource
        end
        print("   Factory " .. maker.makerIndex .. " from " .. sources)
    end

    print("Recipes found: ")
    for _,recipe in pairs(getRecipes()) do
        print("   Recipe: ".. recipe.recipeName .." (" .. recipe.recipeMakesAmount .. "st " .. recipe.recipeMakes..")")
    end

    print( " -- - STARTUP DONE - - --  ")

    commonMain(1, 0.2)
    
end