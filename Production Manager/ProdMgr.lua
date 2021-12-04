
---@type table<string,CraftUnitRecipe>
local allRecipes = {}
---@type CraftUnitRecipe[]
local sortedRecipes = {}

local freeTaskIDs = createLinkedList()

local highTaskID = 1

local FactoryStatuses = {
    UNKNOWN = 0, IDLE = 1, WORKING = 2
}

local TaskStatuses = {
    UNKNOWN = 0, NEED = 1, SCHEDULE = 2, PROCESSING = 3
}

local TaskTypes = {
    UNKNOWN = nil, REQUEST = "request", CRAFT = "craft"
}

---@type LinkedList
local tasks = createLinkedList()

---@type table<number, Task>
local taskMap = {

}

---@type table<string,string>
local alternativeRecipes = {}

local fluidTypes = getFluidTypes()

---@type boolean
local enableIdleCrafting = false

---@class Dependency
---@field public name       string   @Dependency name
---@field public count      number   @The number required
---@field public recipe     Recipe   @Recipe to use
---@field public satisfied  boolean  @Denotes if this dependency is fulfilled or not
---@field public recycle    number   @Notation to the inventory manager that this amount should not be crafted
---@field public subtasks   Task[]   @List of tasks belonging to this dependency
local Dependency = {}


---@class Task
---@field public dependencies Dependency[] @
---@field public needs number @The amount of subtasks needed to complete this task
---@field public type string @The type of request
---@field public recipe Recipe @A reference to the recipe to make this task, may be nil
---@field public target string @The name of the item this task is about
---@field public reportStatus number @Last reported status
---@field public count number @The amount of items this task handles
---@field public rawCount number @Unknown
---@field public rawNeeds number @Unknown
---@field public taskID number @The ID number for this task
---@field public status number @The status of this task
---@field public callback fun(task:Task) @A function to be called when this task completes
---@field public maker CraftUnitMakerData
local Task = {}

---@param name string
---@param count number
---@param recipe Recipe
---@param satisfied boolean
---@return Dependency
function Dependency.new(name, count, recipe, satisfied)
    ---@type Dependency
    local obj = {
        name = name,
        count = count,
        recipe = recipe,
        satisfied = satisfied,
        subtasks = {}
    }
    setmetatable(obj, Dependency)
    Dependency.__index = Dependency
    return obj
end

---@class Maker
---@field public craftUnit
---@field public recipes
---@field public index
---@field public numIndex
---@field public status
local Maker = {}

---@param craftUnit
---@param recipes
---@param index number
---@param status number
---@return Maker
function Maker.new(craftUnit, recipes, index, status)
    if status == nil then
        status = FactoryStatuses.UNKNOWN
    end
    local numIndex = index
    local loc = string.find(numIndex, ":")
    if loc then
        numIndex = string.sub(numIndex, loc + 1)
    end
    ---@type Maker
    local obj = {
        craftUnit = craftUnit,
        recipes = recipes,
        index = index,
        numIndex = numIndex,
        status = status,
    }
    setmetatable(obj, Maker)
    Maker.__index = Maker
    return obj
end


function sucessfullReservation(taskID, resource, reserved)
    local taskItem = taskMap[taskID]
    ---@type Task
    local task = taskItem.value
    for _,d in pairs(task.dependencies) do
        if d.name == resource then
            d.count = d.count - (reserved)
            if d.count <= 0 then
                local taskParent = task.parent
                ---@type Task
                local taskParentValue = taskParent.value
                d.count = 0
                d.satisfied = true
                taskParentValue.needs = taskParentValue.needs - 1
                if taskParentValue.needs == 0 then
                    taskParentValue.status = TaskStatuses.SCHEDULE
                end
                rdebug("Task " .. taskID .. " got " .. resource .. " satisfied by reservation, needs " .. task.needs .. " more dependencies fulfilled")
            else
                rdebug("Task " .. taskID .. " got " .. reserved .. " of " .. resource .. " satisfied by reservation, remaining before fulfilled: " .. d.count)
            end
            return
        end
    end
    rerror("Task " .. taskID .. " was not found in dependencies")
end

function finishedTask(taskID)
    local taskItem = taskMap[taskID]
    if taskItem then
        ---@type Task
        local task = taskItem.value
        task.maker.status = FactoryStatuses.IDLE
        print("Maker " .. task.maker.craftUnit.name .. "[" .. task.maker.index .. "] finished")
        rmessage("Task " .. taskID .. " finished")
        if task.parent then
            local taskParent = task.parent
            ---@type Task
            local taskParentValue = taskParent.value
            local depFound = false
            --printArrayToFile("/lastTask.txt", taskValue, 3)
            --print("Finishing parent " .. taskParentValue.taskID)
            for _,d in pairs(taskParentValue.dependencies) do
                if d.name == task.target or (fluidTypes[task.target] ~= nil and (fluidTypes[task.target].packaged == d.name or fluidTypes[task.target].name == d.name)) then
                    local made = task.count * task.recipe.recipeMakesAmount
                    d.count = d.count - (made)
                    for k,v in pairs(d.subtasks) do
                        if v == task.taskID then
                            table.remove(d.subtasks, k)
                            break
                        end
                    end
                    --d.taskID = nil
                    if d.count <= 0 then
                        d.count = 0
                        d.satisfied = true
                        taskParentValue.needs = taskParentValue.needs - 1
                        if taskParentValue.needs == 0 then
                            taskParentValue.status = TaskStatuses.SCHEDULE
                        end
                        rdebug("Task " .. taskParentValue.taskID .. " got " .. task.target .. " satisfied, needs " .. taskParentValue.needs .. " more dependencies fulfilled")
                    else
                        rdebug("Task " .. taskParentValue.taskID .. " got " .. made .. " of " .. task.target .. " satisfied, remaining before fulfilled: " .. d.count)
                    end
                    depFound = true
                    break
                end
            end
            if depFound == false then
                rerror("Task  " .. tostring(task.taskID) .. " has parent, but dependency for " .. task.target .. " not found")
            end
        elseif task.callback ~= nil then
            task:callback()
        elseif taskItem.callback ~= nil then
            taskItem:callback()
        end
        taskMap[taskID] = nil
        taskItem:delete()
        freeTaskID(task.taskID)
    else
        rerror("Task '" .. tostring(taskID) .. "' not found")
    end
end

function finishedDependency(taskID, resource)
    local task = taskMap[taskID]
    if task ~= nil then
        for _,d in pairs(task.value.dependencies) do
            if d.name == resource then
                for k,v in pairs(d.subtasks) do
                    if v == taskID then
                        table.remove(d.subtasks, k)
                        --d.subtasks[k] = nil
                        break
                    end
                end
                --d.taskID = nil
                d.satisfied = true
                task.value.needs = task.value.needs - 1
                if task.value.needs == 0 then
                    task.value.status = TaskStatuses.SCHEDULE
                end
                --tasks:print(1)
                rdebug("Task " .. taskID .. " got " .. d.name .. " satisfied, needs " .. task.value.needs .. " more dependencies fulfilled")
                return
            end
        end
        rerror("Task dependency for " .. taskID .. " finished, but dependency not found: " .. resource)
    else
        rerror("Task '" .. tostring(taskID) .. "' not found")
    end
end


function getTaskID()
    local taskID
    if freeTaskIDs.first then
        taskID = freeTaskIDs.first.value
        freeTaskIDs.first:delete()
    else
        taskID = highTaskID
        highTaskID = highTaskID + 1
    end
    return taskID
end

function freeTaskID(taskID)
    freeTaskIDs:push(taskID)
end




function scheduler()
    ---@type LinkedListItem
    local schedulerTaskItem = tasks.first
    while schedulerTaskItem ~= nil do
        ---@type Task
        local task = schedulerTaskItem.value
        if task.needs == 0 and task.status == TaskStatuses.SCHEDULE then
            if task.type == TaskTypes.CRAFT then
                for _,maker in pairs(task.recipe.makers) do
                    if maker.status == FactoryStatuses.IDLE then
                        maker.status = FactoryStatuses.WORKING
                        task.maker = maker
                        maker.taskID = task.taskID
                        task.status = TaskStatuses.PROCESSING
                        rmessage("Sending " .. task.taskID .. " for production in " .. maker.craftUnit.name)

                        ---@type CraftUnitMakeOrderParams
                        local params = {
                            index = maker.index,
                            recipeName = task.recipe.recipeName,
                            count = task.count,
                            taskID = task.taskID,
                            target = task.target
                        }
                        scriptInfo.network:send(maker.craftUnit.address, 105, "submitMakeOrder", "json", json.encode(params))
                        return true
                    else
                        if task.reportStatus ~= task.status then
                            print("Task " .. task.taskID .. " is not ready for scheduling. Needs=" .. task.needs .. ", status="..task.status)
                            task.reportStatus = task.status
                        end
                    end
                end
            elseif task.type == TaskTypes.REQUEST then
                ---@type BusMgrOrderParams
                local item = {
                    name = task.target,
                    count = task.count,
                    bus = task.bus,
                    taskID = task.taskID
                }
                rdebug("Request task got fulfilled, sending order to inventory")
                scriptInfo.network:send(scriptInfo.addresses.BusMgr, 100, "order", "json", json.encode(item))
                freeTaskID(task.taskID)
                schedulerTaskItem:delete()
                return true
            end
        else
            if task.reportStatus ~= task.status then
                print("Task " .. task.taskID .. " is not ready for scheduling. Needs=" .. task.needs .. ", status="..task.status)
                task.reportStatus = task.status
            end
        end
        computer.skip()
        schedulerTaskItem = schedulerTaskItem.next
    end
end


---@param dependencyList Dependency[] @The list of dependencies, by reference
---@param recipe Recipe
---@param multiplier number @Initial multiplier to work on
---@return number @The new maximum multiplier
function enumDependencies(dependencyList, recipe, multiplier)
    local regentIndex = 1
    for _,v in pairs(recipe.regents) do
        local name = v.name
        if fluidTypes[name] ~= nil then
            local i = 0
            while (math.floor(v.count)  * multiplier) % fluidTypes[name].unpackCount > 0 do
                multiplier = multiplier + 1
                i = i + 1
                if i >= 10 then
                    print(math.floor(v.count), multiplier)
                    error("Impossible equation")
                end
            end
            break
        end
    end

    for _,v in pairs(recipe.regents) do
        local name = v.name
        local cc
        if fluidTypes[name] ~= nil then
            --printArray(fluidTypes[name])
            name = fluidTypes[name].packaged
            rdebug("Fluid name changed to '" .. name .. "'")
            --printArray(fluidTypes[name])
            if fluidTypes[name] == nil then
                printArrayToFile("fluidTypes.txt", fluidTypes);
            end
            cc = (v.count) * multiplier
            cc = roundUp(cc, fluidTypes[name].unpackCount)
            rdebug("Fluid dependency: " .. name .. " " ..cc .. "x")
        else
            cc = v.count * multiplier
        end
        --regents[regentIndex] = makeRegentItem(name, cc)
        if allRecipes[v.name] ~= nil then
            --enumDependencies(dependencyList, allRecipes[v.name], multiplier * cc)
        end
        regentIndex = regentIndex + 1
        table.insert(dependencyList, Dependency.new(name, cc, v, false))
        --{
        --    name = name,
        --    count = cc,
        --    recipe = v,
        --    satisfied = false,
        --    subtasks = {}
        --})
    end
    return multiplier
end

---@param recipeName string
---@param recipeObj CraftUnitRecipe
---@param count number
---@param target string
---@param taskID number
---@param callback fun()
function scheduleRecipe(recipeName, recipeObj, count, target, taskID, callback)
    print("Found recipe: " .. recipeName)
    local upcount = 0
    if fluidTypes[recipeObj.recipeMakes] ~= nil then
        upcount = 0
        --rdebug("Upcount")
    end
    local taskCount = 0
    local task
    local needs = math.ceil(count / recipeObj.recipeMakesAmount + upcount)
    rdebug("ScheduleRecipe(recipeName=" .. recipeName .. ", count=" .. tostring(count) .. ", target=" .. target .. ", taskID=" .. tostring(taskID) .. ") needs=" .. tostring(needs))
    while needs > 0 do
        ---@type Dependency[]
        local dependencies = {}

        local reserves = {}
        local toMake = math.min(needs, recipeObj.maxOrder)
        if fluidTypes[target] ~= nil then
            toMake = roundUp(toMake, fluidTypes[target].unpackCount)
        end
        toMake = enumDependencies(dependencies, recipeObj, toMake)
        --if fluidTypes[task.target] ~= nil then
        --    if fluidTypes[task.target].packaged == target then
        --        rmessage("Target changed from packaged to fluid type")
        --        target = fluidTypes[task.target].name
        --    end
        --end
        if recipeObj.needsCanisters ~= nil and recipeObj.needsCanisters > 0 then
            local fluid
            if fluidTypes[recipeObj.recipeMakes] ~= nil then
                fluid = fluidTypes[recipeObj.recipeMakes]
            elseif recipeObj.sideProduct ~= nil then
                if fluidTypes[recipeObj.sideProduct] ~= nil then
                    fluid = fluidTypes[recipeObj.sideProduct]
                else
                    error("Side product not fluid : " .. recipeObj.sideProduct)
                end
            else
                error("No fluid to make but has canisters")
            end

            ---@type Dependency
            local dep = {
                name = "Empty Canister",
                count = roundDown(recipeObj.needsCanisters * (toMake - upcount),  fluid.unpackCount) ,
                recycle = recipeObj.givesCanisters * toMake,
                recipe = allRecipes["Empty Canister"],
                satisfied = false,
                onlyReserve = true,
                subtasks = {}
            }
            rdebug("Fluid type return needs " .. tostring(dep.count) .. " canisters, recipe gives " .. tostring(dep.recycle) .. " canisters back")
            if dep.count > 0 then
                table.insert(dependencies, dep)
                rdebug("Reserve " .. tostring(dep.count) .. " empty canisters for " .. recipeName)
            end
        end
        if recipeObj.maxOrder < 1 or toMake < 1 then
            error("Max order for " .. recipeName .. " is " .. recipeObj.maxOrder)
        end
        ---@type Task
        task = {
            reserves = {},
            dependencies = dependencies,
            type = TaskTypes.CRAFT,
            recipe = recipeObj,
            target = target,
            reportStatus = 0,
            count = toMake,
            rawCount = count,
            rawNeeds = needs,
            taskID = getTaskID(),
            status = TaskStatuses.NEED,
            callback = callback
        }
        needs = needs - toMake
        if taskID ~= nil then
            if taskMap[taskID] then
                task.parent = taskMap[taskID]
                --print(task.parent);
                local depSet = false
                --printArrayToFile("task-" .. tostring(taskID) .. ".txt", task, 5)
                for _,v in pairs(task.parent.value.dependencies) do
                    if v.name == task.target then
                        --table.insert(v.subtasks, task.taskID)
                        v.subtasks[#v.subtasks + 1] = task.taskID
                        --v.taskID = task.taskID
                        depSet = true
                    end
                    if fluidTypes[v.name] ~= nil then
                        if fluidTypes[v.name].name == task.target then
                            v.subtasks[#v.subtasks + 1] = task.taskID
                            depSet = true
                        end
                    end
                    computer.skip()
                end
                if not depSet then
                    rerror("Dependency for " .. task.target .. " not found in dependency list of task " .. tostring(task.parent.value.taskID))
                    printArrayToFile("DepNotFoundError.txt", task.parent.value.dependencies, 1)
                end
            else
                rerror("Task '" .. tostring(taskID) .. "' not found")
            end
        end
        local taskItem = tasks:push(task)
        if taskID ~= nil then
            rdebug("  Created subtask ID " .. tostring(task.taskID) .. " of " .. task.count .. " items for " .. tostring(taskID))
        else
            rdebug("  Created subtask ID " .. tostring(task.taskID) .. " of " .. task.count .. " items")
        end
        taskMap[task.taskID] = taskItem
        task.needs = #dependencies
        for _,d in pairs(dependencies) do
            rmessage("Reserving " .. tostring(d.count) .. " " .. d.name .. " for task ".. tostring(task.taskID))
            ---@type BusMgrReserveParams
            local data = {
                name = d.name,
                count = d.count,
                taskID = task.taskID
            }
            if d.recycle then
                data.recycle = d.recycle
            end
            scriptInfo.network:send(scriptInfo.addresses.BusMgr, 100, "reserve", "json", json.encode(data))
            computer.skip()
        end
        taskCount = taskCount + 1
        wait(10)
    end
    if taskID ~= nil then
        rmessage("Order of " .. count .. " " .. target .. " for task " .. tostring(taskID) .. " submitted. Created ".. taskCount .. " new task(s)")
    else
        rmessage("Order of " .. count .. " " .. target .. " submitted. Created ".. taskCount .. " new task(s)")
    end

    return task
end


---@param target string @Target name
---@param count number @The amount of items to process
---@param taskID number @Task ID of parent task, nil if none
---@param callback fun(task:Task) @Callback function
function submitWork(target, count, taskID, callback)
    print( "submitWork(" .. target .. ", " .. tostring(count) .. ", " .. tostring(taskID))
    if fluidTypes[target] then
        if fluidTypes[target].packaged == target then
            target = fluidTypes[target].name
            if taskID ~= nil then
                rmessage("Target changed from packaged to fluid type, " .. target .. ", parent task " .. taskID)
            else
                rmessage("Target changed from packaged to fluid type, " .. target)
            end
        end
    end
    local recipeName = target
    if alternativeRecipes[target] ~= nil then
        recipeName = alternativeRecipes[target]
    end
    -- Look for primary recipe output
    for _,v in pairs(allRecipes) do
        if v.recipeName == recipeName then
            return scheduleRecipe(recipeName, v, count, target, taskID, callback)
        end
    end
    for _,v in pairs(allRecipes) do
        if v.recipeName == "Roze " .. recipeName then
            return scheduleRecipe(recipeName, v, count, target, taskID, callback)
        end
    end

    rerror("No recipe to craft " .. target)

    ArrayPrinter.new(allRecipes):printToFile("RecipeError-all.txt")
    ArrayPrinter.new(fluidTypes):printToFile("RecipeError-fluids.txt")

    error()
end

function submitOrder(itemName, count, bus)
    print( "submitOrder(" .. itemName .. ", " .. tostring(count) .. ", " .. tostring(taskID) .. ", " .. bus)
    local needs = count
    local taskCount = 0
    while needs > 0 do
        ---@type number
        local toMake = math.min(needs, stackSize[itemName])

        ---@type Dependency[]
        local dependencies = { Dependency.new(itemName, toMake, false) }
        --{
        --    name = itemName,
        --    count = toMake,
        --    satisfied = false,
        --    subtasks = {}
        --}
        ---@type Task
        local task = {
            dependencies = dependencies,
            type = "request",
            target = itemName,
            bus = bus,
            reportStatus = 0,
            count = toMake,
            rawCount = count,
            rawNeeds = needs,
            taskID = getTaskID(),
            status = TaskStatuses.NEED,
        }
        needs = needs - toMake
        task.needs = #dependencies
        local taskItem = tasks:push(task)
        taskMap[task.taskID] = taskItem
        for _,d in pairs(dependencies) do
            scriptInfo.network:send(scriptInfo.addresses.BusMgr, 100, "reserve", "json", json.encode{
                name = d.name,
                count = d.count,
                taskID = task.taskID
            })
        end
        taskCount = taskCount + 1
    end
    rmessage("Request for " .. count .. " " .. itemName .. " submitted. Created ".. taskCount .. " new task(s)")
    return
end

--{{{ Panel Stuff
local inputRecipeIndex = 1
local inputRecipeCount = 1

local recipeCount = 0

local txtRecipe
local strCurrentRecipeName


---@type IndicatorModule
local indWStatus
---@type IndicatorModule
local indStatus
---@type MicroDisplayModule
local dispCountInProd
---@type MicroDisplayModule
local dispCountNeedMats
---@type MicroDisplayModule
local dispCountSchedulable
---@type MicroDisplayModule
local dispCount
---@type MicroDisplayModule
local dispProduct
local target = "Store"


function updateStatus()
    local err = 0
    local ok = 1
    local warning = 0
    local brightness = 0.5
    local panel2 = component.proxy(component.findComponent("ProdMgr_WallPanel2")[1])
    indStatus = panel2:getXModule(5)
    if err > 0 then
        indStatus:setColor(1, 0.1, 0.1, brightness)
    elseif warning > 0 then
        indStatus:setColor(1, 1, 0.1,   brightness)
    elseif ok > 0 then
        indStatus:setColor(0, 0.5, 0.0, brightness)
    else
        indStatus:setColor(1, 0.5, 0.0, brightness)
    end
    computer.skip()
    local taskItem = tasks.first
    err = 0;
    warning = 0;
    ok = 0
    local countProd = 0
    local countNeed = 0
    local countSched = 0
    while taskItem ~= nil do
        local task = taskItem.value
        if task.status == TaskStatuses.NEED then
            countNeed = countNeed + 1
            err = err + 1
        elseif task.status == TaskStatuses.SCHEDULE then
            countSched = countSched + 1
            warning = warning + 1
        elseif task.status == TaskStatuses.PROCESSING then
            countProd = countProd + 1
            ok = ok + 1
        end
        taskItem = taskItem.next
        computer.skip()
    end

    dispCountInProd:setText(tostring(countProd))
    dispCountSchedulable:setText(tostring(countSched))
    dispCountNeedMats:setText(tostring(countNeed))


    if err > 0 then
        indWStatus:setColor(1, 1, 0.1, brightness)
    elseif warning > 0 then
        indWStatus:setColor(1, 1, 0.1, brightness)
    elseif ok > 0 then
        indWStatus:setColor(0, 0.5, 0.0, brightness)
    else
        indWStatus:setColor(0, 0, 0, brightness)
    end

    dispCount:setText(inputRecipeCount)
    dispProduct:setText(strCurrentRecipeName)
    computer.skip()
    return false
end


function printAssisBox(gpu)
    local systemColors = scriptInfo.systemColors
    local x = 277
    local y = 58
    rsSetColorA(gpu, systemColors.Grey)
    gpu:setText(x, y + 0, "╔═════════════════════╗")
    gpu:setText(x, y + 1, "║                     ║") -- 21 wide
    gpu:setText(x, y + 2, "║                     ║")
    gpu:setText(x, y + 3, "║                     ║")
    gpu:setText(x, y + 4, "║                     ║")
    gpu:setText(x, y + 5, "║                     ║")
    gpu:setText(x, y + 6, "║                     ║")
    gpu:setText(x, y + 7, "╚═════════════════════╝")
    --gpu:setText(x, y + 0, "-----------------------")
    --gpu:setText(x, y + 1, "|                     |")
    --gpu:setText(x, y + 2, "|                     |")
    --gpu:setText(x, y + 3, "|                     |")
    --gpu:setText(x, y + 4, "|                     |")
    --gpu:setText(x, y + 5, "|                     |")
    --gpu:setText(x, y + 6, "|                     |")
    --gpu:setText(x, y + 7, "-----------------------")
    --print("╔═════════════════════╗")
    rsSetColorA(gpu, systemColors.Normal)
    gpu:setText(x + 1, y + 1, "Recipe: ")
    local str = strCurrentRecipeName
    if str then
        rsSetColorA(gpu, systemColors.LightBlue)
        if string.len(str) > 20 then
            str = string.sub(str, 1, 20)
        end
        gpu:setText(x + 2, y + 1 * 2, str)
    end
    rsSetColorA(gpu, systemColors.Normal)
    gpu:setText(x + 1, y + 1 * 3, "Amount: ")
    rsSetColorA(gpu, systemColors.Number)
    gpu:setText(x + 19, y + 1 * 3, lpad(tostring(inputRecipeCount), 3, " "))
    --rsSetColorA(gpu, systemColors.Normal)
    --if multiplier < 10 then
    --    gpu:setText(x + 20, y + 4, "+")
    --    rsSetColorA(gpu, systemColors.Number)
    --    gpu:setText(x + 21, y + 4, tostring(multiplier))
    --elseif multiplier < 100 then
    --    gpu:setText(x + 19, y + 4, "+")
    --    rsSetColorA(gpu, systemColors.Number)
    --    gpu:setText(x + 20, y + 4, tostring(multiplier))
    --end
    rsSetColorA(gpu, systemColors.Normal)
    gpu:setText(x + 1, y + 1 * 5, "Send to: ")
    rsSetColorA(gpu, systemColors.LightBlue)
    if target == "store" then
        gpu:setText(x + 15, y + 1 * 5, "Storage")
    elseif target == "user" then
        gpu:setText(x + 18, y + 1 * 5, "User")
    elseif target == "trash" then
        gpu:setText(x  + 11, y + 1 * 5, "Destruction")
    else
        rsSetColorA(gpu, systemColors.LightRed)
        gpu:setText(x + 15, y + 1 * 5, "Unknown")
    end
    rsSetColorA(gpu, systemColors.Normal)
    gpu:setText(x + 8, y + 1 * 6, "Idle Craft: ")
    if enableIdleCrafting then
        rsSetColorA(gpu, systemColors.LightBlue)
        gpu:setText(x + 20, y + 1 * 6, "On")
    else
        rsSetColorA(gpu, systemColors.Normal)
        gpu:setText(x + 19, y + 1 * 6, "Off")
    end
    computer.skip()


end

function setRecipeIndex(index)
    inputRecipeIndex = math.min(recipeCount, math.max(1, index))
    if sortedRecipes[inputRecipeIndex] ~= nil then
        strCurrentRecipeName = sortedRecipes[inputRecipeIndex].recipeName
        print(index .. " - " .. inputRecipeIndex .. " - " ..strCurrentRecipeName)
    else
        inputRecipeIndex = 1
        if sortedRecipes[inputRecipeIndex] ~= nil then
            strCurrentRecipeName = sortedRecipes[inputRecipeIndex].recipeName
        else
            strCurrentRecipeName = "<no recipes>"
        end
    end
end

function initWallPanel()
    local litButtonAlpha = 0.6

    local panel1 = component.proxy(component.findComponent("ProdMgr_WallPanel1")[1])
    local panel2 = component.proxy(component.findComponent("ProdMgr_WallPanel2")[1])
    local panel3 = component.proxy(component.findComponent("ProdMgr_WallPanel3")[1])

    ---@type PushbuttonModule
    local btnWSubmit = panel2:getXModule(2)
          indStatus = panel2:getXModule(5)
          indWStatus = panel2:getXModule(4)
          dispCountInProd = panel3:getXModule(5)
          dispCountSchedulable = panel3:getXModule(4)
          dispCountNeedMats = panel3:getXModule(3)

          dispProduct = panel3:getXModule(1)
          dispCount = panel3:getXModule(0)

    ---@type PushbuttonModule
    local btnWPreviouRecipe = panel1:getXModule(5)

    ---@type PushbuttonModule
    local btnWNextRecipe = panel1:getXModule(4)

    ---@type PushbuttonModule
    local btnDumpInventory = panel2:getXModule(3)


    --local btnWIncreaseAmount = panel1:getXModule(2)
    --local btnWDecreaseAmount = panel1:getXModule(1)

    --local swWMultiplier = panel1:getXModule(0)
    ---@type MCP_Mod_3Pos_Switch_C
    local swTarget = panel2:getXModule(0)
    ---@type MCP_Mod_2Pos_Switch_C
    local swIdleCraft = panel2:getXModule(1)

    ---@type PushbuttonModule
    local btnAmount0 = panel1:getXModule(3)
    ---@type MCP_Mod_Encoder_C
    local encAmount1 = panel1:getXModule(2)
    ---@type MCP_Mod_Encoder_C
    local encAmount10 = panel1:getXModule(1)
    ---@type MCP_Mod_Encoder_C
    local encAmount100 = panel1:getXModule(0)

    --setCommandLabelText(panel1, 5, "Previous\nRecipe", false)
    --setCommandLabelText(panel1, 4, "Next\nRecipe", false)
    --setCommandLabelText(panel1, 3, "", false)
    --setCommandLabelText(panel1, 2, "Amount\n+", false)
    --setCommandLabelText(panel1, 1, "Amount\n-", false)
    --setCommandLabelText(panel1, 0, "   +10\n    +1", false)
--
    --setCommandLabelText(panel2, 5, "Status", false)
    --setCommandLabelText(panel2, 4, "N/U", false)
    --setCommandLabelText(panel2, 3, "", false)
    --setCommandLabelText(panel2, 2, "Submit\nWork", false)
    --setCommandLabelText(panel2, 1, "", false)
    --setCommandLabelText(panel2, 0, "", false)


    dispCountInProd:setColor(0.2, 1, 0.2, 0.5)
    dispCountInProd:setText("0")
    dispCountSchedulable:setColor(1, 1, 0.2, 0.5)
    dispCountSchedulable:setText("0")
    dispCountNeedMats:setColor(1, 0.2, 0.2, 0.5)
    dispCountNeedMats:setText("0")
    dispProduct:setColor(0.6, 0.6, 0.6, 0.5)
    dispProduct:setText("")
    dispCount:setColor(0.6, 0.6, 0.6, 0.5)
    dispCount:setText("0")

    indWStatus:setColor(0.1, 0.1, 0.1, 0)
    initModularButton(encAmount1,
            function(_, _, params)
                inputRecipeCount = inputRecipeCount + params[3]
                if(inputRecipeCount < 0) then
                    inputRecipeCount = 0
                end
                printScreen()
            end,
            rgba(0,0,0,0), true
    )
    initModularButton(encAmount10,
            function(_, _, params)
                inputRecipeCount = inputRecipeCount + params[3] * 10
                if(inputRecipeCount < 0) then
                    inputRecipeCount = 0
                end
                printScreen()
            end,
            rgba(0,0,0,0), true
    )
    initModularButton(encAmount100,
            function(_, _, params)
                inputRecipeCount = inputRecipeCount + params[3] * 100
                if(inputRecipeCount < 0) then
                    inputRecipeCount = 0
                end
                printScreen()
            end,
            rgba(0,0,0,0), true
    )
    initModularButton(btnAmount0,
            function(_, _, _)
                inputRecipeCount = 0
                printScreen()
            end,
            rgba(0,0,0,0), true
    )


    initModularButton(
            btnWSubmit,
            function(self, _, _)

                local recipe
                if sortedRecipes[inputRecipeIndex] ~= nil then
                    recipe = sortedRecipes[inputRecipeIndex]
                    self:setColor(0, 1, 0, litButtonAlpha)
                else
                    self:setColor(1, 0, 0, litButtonAlpha)
                end

                if recipe ~= nil then
                    if target == "store" then
                        submitWork(recipe.recipeName, inputRecipeCount)
                    elseif target == "user" then
                        submitOrder(recipe.recipeMakes, inputRecipeCount, "UserRequestA")
                    end
                end

                printScreen()
                wait(1000)
                self:setColor(0, 1, 0, 0)
            end,
            rgba(0, 1, 0, 0),
            true
    )
    initModularButton(
            btnWPreviouRecipe,
            function(self, _, _)
                self:setColor(0, 0, 1, litButtonAlpha)



                --inputRecipeIndex = math.max(1, inputRecipeIndex - 1)
                setRecipeIndex(inputRecipeIndex - 1)
                --local i = 1
                --for _,v in pairs(sortedRecipes) do
                --    if i == inputRecipeIndex then
                --        print(v.recipeName)
                --        strCurrentRecipeName = v.recipeName
                --        break
                --    end
                --    i = i + 1
                --end


                printScreen()
                wait(100)
                self:setColor(0, 0, 0.3, 0)
            end,
            rgba(0, 0, 0.3, 0),
            true
    )
    initModularButton(
            btnWNextRecipe,
            function(self, _, _)
                self:setColor(0, 0, 1, litButtonAlpha)
                setRecipeIndex(inputRecipeIndex + 1)
                --for _,v in pairs(sortedRecipes) do
                --    if i == inputRecipeIndex then
                --        print(v.recipeName)
                --        strCurrentRecipeName = v.recipeName
                --        break
                --    end
                --    i = i + 1
                --end
                printScreen()
                wait(100)
                self:setColor(0, 0, 0.3, 0)
            end,
            rgba(0, 0, 0.3, 0),
            true
    )
    initModularButton(btnDumpInventory, function(self, parameters)
        self:setColor(0, 0, 1, litButtonAlpha)
        scriptInfo.network:send(scriptInfo.addresses.InvMgr1, 106, "dumpInventory")
        scriptInfo.network:send(scriptInfo.addresses.InvMgr2, 106, "dumpInventory")
        wait(100)
        self:setColor(0, 0, 0.3, 0)
    end, rgba(0, 0, 0.3, 0), true)
    --initModularButton(
    --        btnWDecreaseAmount,
    --        function(self, msg, params)
    --            self:setColor(0, 0, 1, litButtonAlpha)
--
    --            inputRecipeCount = inputRecipeCount - multiplier
--
    --            if inputRecipeCount <= 0 then
    --                inputRecipeCount = 0
    --            end
--
    --            printScreen()
    --            wait(100)
    --            self:setColor(0, 0, 0.3, 0)
    --        end,
    --        rgba(0, 0, 0.3, 0),
    --        true
    --)
    --initModularButton(
    --        btnWIncreaseAmount,
    --        function(self, msg, params)
    --            self:setColor(0, 0, 1, litButtonAlpha)
--
    --            inputRecipeCount = inputRecipeCount + multiplier
--
    --            if inputRecipeCount > 100 then
    --                inputRecipeCount = 100
    --            end
--
    --            printScreen()
    --            wait(100)
    --            self:setColor(0, 0, 0.3, 0)
    --        end,
    --        rgba(0, 0, 0.3, 0),
    --        true
    --)
    --initModularButton(
    --        swWMultiplier,
    --        function(self, msg, params)
    --            self:setColor(0, 0, 1, litButtonAlpha)
    --            --print("swWMultiplier: " .. msg)
    --            --printArray(params)
    --            if params[3] == true then
    --                multiplier = 10
    --            else
    --                multiplier = 1
    --            end
    --            printScreen()
    --            wait(1000)
    --            self:setColor(0, 0, 0, 0)
    --        end,
    --        rgba(0, 0, 0, 0),
    --        true
    --)
    local swTargetColor_User = rgba(0, 1, 0, litButtonAlpha / 3)
    local swTargetColor_Store = rgba(0.4, 0.4, 1, litButtonAlpha / 3)
    local swTargetColor_Trash = rgba(1, 0.4, 0.4, litButtonAlpha / 3)
    local swIdleCraftColor_On = rgba(0, 1, 0, litButtonAlpha / 3)
    local swIdleCraftColor_Off = rgba(0, 0, 0, 0)
    initModularButton(
            swTarget,
            function(self, _, params)
                --print("swWMultiplier: " .. msg)
                --printArray(params)
                if params[3] == 2 then
                    target = "user"
                    setModuleColor(self, swTargetColor_User)
                elseif params[3] == 1 then
                    target = "store"
                    setModuleColor(self, swTargetColor_Store)
                else
                    target = "trash"
                    setModuleColor(self, swTargetColor_Trash)
                end
                printScreen()
                wait(100)
            end,
            rgba(0, 0, 0, 0),
            true
    )
    print("State: " .. tostring(swTarget.state))
    if swTarget.state == 2 then
        setModuleColor(swTarget, swTargetColor_User)
        target = "user"
    elseif swTarget.state == 1 then
        setModuleColor(swTarget, swTargetColor_Store)
        target = "store"
    elseif swTarget.state == 0 then
        setModuleColor(swTarget, swTargetColor_Trash)
        target = "trash"
    end

    initModularButton(
            swIdleCraft,
            function(self, _, params)
                print("Idle crafting buttons: " .. tostring(params[3]))
                if params[3] == true then
                    enableIdleCrafting = true
                    setModuleColor(self, swIdleCraftColor_On)
                    queueLowStockIfIdle(true)
                else
                    enableIdleCrafting = false
                    setModuleColor(self, swIdleCraftColor_Off)
                end
                printScreen()
                wait(100)
            end,
            nil,
            true
    )
    if swIdleCraft.state == true then
        enableIdleCrafting = true
        setModuleColor(swIdleCraft, swIdleCraftColor_On)
    else
        enableIdleCrafting = false
        setModuleColor(swIdleCraft, swIdleCraftColor_Off)
    end
    --if swWMultiplier.state == true then
    --    multiplier = 10
    --else
    --    multiplier = 1
    --end
    --if swTarget.state == true then
    --    target = "user"
    --    swTarget:setColor(0, 1, 0, litButtonAlpha / 2)
    --else
    --    target = "store"
    --    swTarget:setColor(0.4, 0.4, 1, litButtonAlpha / 2)
    --end
    schedulePeriodicTask(PeriodicTask.new(function(_) updateStatus(); end), indStatus)
    --periodicStuff:push({
    --    func = function()
    --        updateStatus()
    --    end,
    --    ref = indStatus
    --})
    computer.skip()
end
--}}}

function caluclateMaxOrder(recipe)
    local breakLoop = false
    local maxMultiplier = 1
    while true do
        for _,_s in pairs(recipe.regents) do
            if stackSize[_s.name] and _s.count * maxMultiplier > stackSize[_s.name] then
                maxMultiplier = maxMultiplier - 1
                breakLoop = true
                break
            elseif not stackSize[_s.name] then
                error("No stack size for " .. _s.name)
            end
            computer.skip()
        end
        if breakLoop then
            break
        end
        maxMultiplier = maxMultiplier + 1
    end
    if maxMultiplier < 1 then
        --printArray(recipe, 1)
        --printArray(recipe.regents, 1)
        error("Max multiplier < 0")
    end
    return maxMultiplier
end

local craftUnits = {}

---@generic T
---@type fun(table:T[],function:fun(a:T,b:T))
local qsort = filesystem.doFile("qsort.lua")

---@param a CraftUnitRecipe
---@param b CraftUnitRecipe
function recipeSortFunction(a, b)
    return string.upper(a.recipeMakes) < string.upper(b.recipeMakes)
end

function sortRecipes()
    sortedRecipes = {}
    local i = 1
    for _,v in pairs(allRecipes) do
        table.insert(sortedRecipes, v)
        if string.len(v.recipeName) > 11 then
            if string.sub(v.recipeName, 1, 11) == "Alternate: " then
                v.isAlternative = true
            end
        end
        computer.skip()
        i = i + 1
    end
    print(tostring(i - 1) .. " recipes copied")
    --coroutine.resume(coroutine.create(function ()
    --    table.sort(sortedRecipes, function (a,b)
    --        return string.upper(a.recipeMakes) < string.upper(b.recipeMakes)
    --    end)
    --    print("Meow")
    --    mutex = true
    --end))
    qsort(sortedRecipes, recipeSortFunction)
    setRecipeIndex(inputRecipeIndex)
    print("Sort complete")
end

local lowStock = {}


--{{{ Network
function initNetwork()
    networkHandler(100, nil, { -- table of message handlers
        ---@param parameters CraftUnitInfo
        allMakerData = function(address, parameters)
            ---@type CraftUnitData
            local craftUnit = {
                name = parameters.craftUnit,
                comment = parameters.comment,
                address = address,
                recipes = {},
                makers = {}
            }
            craftUnits[address..":"..craftUnit.name] = craftUnit
            printArray(parameters)
            rmessage("Received data for " .. tostring(countAssocTable(parameters.recipes)) .. " recipes and " .. tostring(countAssocTable(parameters.makers)) .. " makers from " .. parameters.craftUnit)
            --printArray(parameters, 0)
            --printArray(craftUnit, 1)
            for _,recipe in pairs(parameters.recipes) do
                local name = recipe.recipeName
                if allRecipes[name] == nil then
                    --print("Making recipe")
                    recipe.maxOrder = caluclateMaxOrder(recipe)
                    allRecipes[name] = recipe
                    if recipeCount == 1 then
                        strCurrentRecipeName = name
                        if txtRecipe then
                            txtRecipe.text = strCurrentRecipeName
                        end
                    end
                    recipeCount = recipeCount + 1
                    --craftUnits[address].recipes[parameters.recipeName] = allRecipes[parameters.recipeName]
                    allRecipes[name].makers = {}
                end
                craftUnit.recipes[name] = allRecipes[name]
                --print(allRecipes[name])
                --print(recipe.recipeName)
            end
            for _,makerData in pairs(parameters.makers) do
                computer.skip()
                local maker = Maker.new(craftUnit, craftUnit.recipes, makerData.index)
                --print("Recieved maker " .. tostring(maker.index) .. " from " .. craftUnit.name)
                craftUnit.makers[maker.index] = maker
                --print("Maker.... ")
                maker.status = makerData.status
                for _,v in pairs(craftUnit.recipes) do
                    --print("Insert maker")
                    allRecipes[v.recipeName].makers[craftUnit.name .. "_" .. tostring(maker.index)] = maker
                    --table.insert(, maker)
                end
            end
            --printArray(craftUnit.recipes, 1)
            --error("A")
            sortRecipes()
        end,
        ---@param parameters ProdMgrSubmitWorkMsg
        submitWork = function(_, parameters)
            if parameters.reserved then
                sucessfullReservation(parameters.taskID, parameters.name, parameters.reserved)
            end
            submitWork(parameters.name, parameters.count, parameters.taskID)
        end,
        ---@param parameters ProdMgrRequestToMsg
        requestTo = function(_, parameters)
            submitOrder(parameters.name, parameters.count, parameters.bus)
        end,
        ---@param parameters ProdMgrFinishedTask
        finishedTask = function(address, parameters)
            finishedTask(parameters.taskID)
            local craftUnit = craftUnits[address]
            if craftUnit ~= nil then
                for _,v in pairs(craftUnit.makers) do
                    if v.status == FactoryStatuses.WORKING and v.index == parameters.factoryIndex then
                        v.status = FactoryStatuses.IDLE
                        rwarning("Rouge machine in " .. craftUnit.name .. " cleared")
                        break
                    end
                end
            end
        end,
        ---@param parameters ProdMgrDependencyFinishedMsg
        dependencyFinished = function(_, parameters)
            finishedDependency(parameters.taskID, parameters.name)
        end,
        dumpAll = function()
            rdebug("Dumping data to files")
            printArrayToFile("temp.txt", craftUnits, 4)
            printArrayToFile("temp2.txt", allRecipes, 4)
        end,
        lowStock = function(_, parameters)
            print("Low stock data received")
            --local oldStock = lowStock
            for k,v in pairs(parameters) do
                lowStock[k] = v
            end
            if enableIdleCrafting then
                queueLowStockIfIdle(true)
            end
        end
    })
end
--}}}

local lastLowStock = 0
local lowStockOutstanding = {}
local LOW_STOCK_TIMEOUT = 60000

function queueLowStockIfIdle(forced)
    local tick = computer.millis()
    if tick - lastLowStock > LOW_STOCK_TIMEOUT and tasks.length < 30 and enableIdleCrafting or forced then
        if lowStock ~= nil then
            for itemID,item in pairs(lowStock) do
                for _,v in pairs(allRecipes) do
                    if v.recipeName == item.name then
                        rdebug("Low stock on " .. item.name .. ", ordering " .. tostring(v.maxOrder) .. " units")
                        if lowStockOutstanding[item.name] == nil then
                            lowStockOutstanding[item.name] = v.maxOrder
                            item.ordered = v.maxOrder
                            local task = submitWork(v.recipeName, v.maxOrder, nil, function(task)
                                if task.lowStockOrder ~= nil then
                                    local recipe = task.lowStockOrder.name
                                    if lowStockOutstanding[recipe] ~= nil then
                                        lowStockOutstanding[recipe] = lowStockOutstanding[recipe] - task.lowStockOrder.ordered
                                        if lowStockOutstanding[recipe] <= 0 then
                                            lowStockOutstanding[recipe] = nil
                                        end
                                        rdebug("Low stock order finished " .. recipe .. " outstanding removed")
                                    else
                                        rdebug("Low stock order finished " .. recipe)
                                    end
                                end
                            end)
                            task.lowStockOrder = item
                        else
                            print("Already in production: " .. item.name)
                        end
                        table.remove(lowStock, itemID)
                        return true
                    end
                    computer.skip()
                end
                computer.skip()
            end
        else
            print("No low stock data")
        end
        lastLowStock = tick
    end
    return false
end

function initLowStockQueueing()
    schedulePeriodicTask(PeriodicTask.new(function() return queueLowStockIfIdle()  end))
    --periodicStuff:push({
    --    func = function()
    --        return queueLowStockIfIdle()
    --    end,
    --    ref = nil,
    --})
end


function requestMakers()
    print("Requesting craft units... ")
    scriptInfo.network:broadcast(105, "pushMakerInfo")
end



--{{{ Printing stuff

local StateColors = {}
StateColors[TaskStatuses.UNKNOWN] = rgba(0.5,0.5,0.5,1)
StateColors[TaskStatuses.PROCESSING] = rgba(0.5,1,0.5,1)
StateColors[TaskStatuses.NEED] = rgba(1,0.5,0.5,1)
StateColors[TaskStatuses.SCHEDULE] = rgba(1,0.78,0.45,1)
local StateToString = {}
StateToString[TaskStatuses.UNKNOWN] = "Unkn"
StateToString[TaskStatuses.PROCESSING] = "Proc"
StateToString[TaskStatuses.NEED] = "Need"
StateToString[TaskStatuses.SCHEDULE] = "Schd"

local QUEUE_COL_WIDTH = 40
local CRAFT_COL_WIDTH = 35
local QUEUE_X_INSET = 2
local ID_COLOR = rgba(0.6, 0.2, 0.7, 1)
local AMOUNT_COLOR = rgba(0.4, 0.4, 0.8, 1)
local TREE_COLOR = rgba(0.3, 0.3, 0.3, 0.5)


---@param gpu GPU_T1_C
---@param x number
---@param y number
---@param dependency Dependency
function printDependency(gpu, x, y, dependency)
    local _x = x
    if dependency.satisfied then
        rsSetColorA(gpu, scriptInfo.systemColors.Green);
    else
        rsSetColorA(gpu, scriptInfo.systemColors.Yellow);
    end
    gpu:setText(x, y, dependency.name)
    x = x + string.len(dependency.name .. " ")
    rsSetColorA(gpu, scriptInfo.systemColors.Number);
    gpu:setText(x, y, lpad(tostring(dependency.count), 3, " "))
    x = _x
    x, y = rsadvanceY(x, y, QUEUE_COL_WIDTH);
    local depCount = #dependency.subtasks
    local depIndex = 1
    local ly = y
    local lx = x
    for _,v in pairs(dependency.subtasks) do
        local ltask = taskMap[v]
        if ltask ~= nil then
            rsSetColorA(gpu, TREE_COLOR);
            if depIndex < depCount then
                gpu:setText(x, y, "├")
            else
                gpu:setText(x, y, "└")
            end
            if y < ly then
                for i = ly + 1, scriptInfo.screenHeight do
                    gpu:setText(lx, i, "│")
                end
                ly = -1
            end
            if y - ly > 0 then
                for i = ly + 1, y - 1 do
                    gpu:setText(x, i, "│")
                end
            end
            ly = y
            lx = x
            x, y = printTask2(gpu, x + QUEUE_X_INSET, y, ltask.value);
            x = x - QUEUE_X_INSET
            depIndex = depIndex + 1
        end
    end

    computer.skip()
    return x, y;
end


---@param gpu GPU_T1_C
---@param x number
---@param y number
---@param task Task
function printTask(gpu, x, y, task)
    --printArray(task, 1)
    rsSetColorA(gpu, scriptInfo.systemColors.Number);
    local temp = lpad(tostring(task.taskID), 3, " ")
    gpu:setText(x, y, temp)
    x = x + string.len(temp)
    if task.parent ~= nil then
        rsSetColorA(gpu, scriptInfo.systemColors.Normal);
        temp = lpad(tostring(task.taskID), 3, " > ")
        gpu:setText(x, y, temp)
        x = x + string.len(temp)
        rsSetColorA(gpu, scriptInfo.systemColors.Orange);
        temp = lpad(tostring(task.parent.value.taskID), 3, " ")
        gpu:setText(x, y, temp)
        x = x + string.len(temp)
    end
    rsSetColorA(gpu, scriptInfo.systemColors.Normal);
    gpu:setText(x, y, ": ")
    x = x + 2
    rsSetColorA(gpu, scriptInfo.systemColors.Number);
    temp = lpad(tostring(task.count), 3, " ")
    gpu:setText(x, y, temp)
    x = x  + string.len(temp)
    rsSetColorA(gpu, scriptInfo.systemColors.Normal);
    gpu:setText(x, y, "x")
    x = x + 2
    gpu:setText(x, y, task.target)
    x = x + string.len(task.target) + 4
    --print("Status: '"..tostring(task.status).."'")
    rsSetColorA(gpu, StateColors[task.status]);
    gpu:setText(x, y, StateToString[task.status]); y = y + 1
    computer.skip()
end

---@param gpu GPU_T1_C
---@param x number
---@param y number
---@param task Task
function printTask2(gpu, x, y, task)
    local _x = x
    --printArray(task, 1)
    rsSetColorA(gpu, ID_COLOR);
    local id = tostring(task.taskID)
    gpu:setText(x, y, id)
    x = x + string.len(id)
    --if task.parent ~= nil then
    --    rsSetColorA(gpu, scriptInfo.systemColors.Normal);
    --    gpu:setText(" > ", x, y,lpad(tostring(task.taskID, 3)))
    --    x = x + 3
    --    rsSetColorA(gpu, scriptInfo.systemColors.Orange);
    --    gpu:setText(" ", x, y,lpad(tostring(task.parent.value.taskID, 3)))
    --    x = x + 3
    --end
    rsSetColorA(gpu, scriptInfo.systemColors.Normal);
    gpu:setText(x, y, ": ")
    x = x + 2
    if task.lowStockOrder ~= nil then
        rsSetColorA(gpu, scriptInfo.systemColors.Orange);
        gpu:setText(x, y, "↑")
        x = x + 2
    end
    rsSetColorA(gpu, AMOUNT_COLOR);
    local count = tostring(task.count)
    gpu:setText(x, y, count)
    x = x + string.len(count)
    rsSetColorA(gpu, scriptInfo.systemColors.Normal);
    gpu:setText(x, y, "x")
    x = x + 2
    gpu:setText(x, y, task.target)
    x = x + string.len(task.target) + 1
    --print("Status: '"..tostring(task.status).."'")
    if StateColors[task.status] == nil then
        printArray(task, 2)
        rerror("Invalid task status? " .. task.status)
        error("Die")
    end
    rsSetColorA(gpu, scriptInfo.systemColors.Normal);
    gpu:setText(x, y, "("); x = x + 1
    rsSetColorA(gpu, StateColors[task.status]);
    local statusStr = StateToString[task.status]
    gpu:setText(x, y, statusStr);
    x = x + string.len(statusStr)
    rsSetColorA(gpu, scriptInfo.systemColors.Normal);
    gpu:setText(x, y, ")");
    x = _x
    x, y = rsadvanceY(x, y, QUEUE_COL_WIDTH);
    local depCount = #task.dependencies
    local depIndex = 1
    local ly = y
    local lx = x
    for _,v in pairs(task.dependencies) do
        rsSetColorA(gpu, TREE_COLOR);
        if depIndex < depCount then
            gpu:setText(x, y, "├")
        else
            gpu:setText(x, y, "└")
        end
        if y < ly then
            for i = ly + 1, scriptInfo.screenHeight do
                gpu:setText(lx, i, "│")
            end
            ly = -1
        end
        if y - ly > 0 then
            for i = ly + 1, y - 1 do
                gpu:setText(x, i, "│")
            end
        end
        ly = y
        lx = x
        --if ltask ~= nil then
        --    x, y = printTask2(x + QUEUE_X_INSET, y, ltask.value);
        --    x = x - QUEUE_X_INSET
        --else
        x, y = printDependency(gpu, x + QUEUE_X_INSET, y, v)
        x = x - QUEUE_X_INSET
        --x, y = rsadvanceY(x, y, QUEUE_COL_WIDTH);
        --end
        depIndex = depIndex + 1
    end

    computer.skip()
    return x, y;
end

---@param gpu GPU_T1_C
---@param x number
---@param y number
---@param maker Maker
function printMaker(gpu, x, y, maker)
    local systemColors = scriptInfo.systemColors
    local str = maker.craftUnit.name
    rsSetColorA(gpu, systemColors.LightBlue)
    str = tostring(maker.numIndex)
    gpu:setText(x, y, str)
    x = x + string.len(str) + 2
    if maker.status == FactoryStatuses.UNKNOWN then
        rsSetColorA(gpu, systemColors.Grey)
        gpu:setText(x, y, "UNKNOWN")
        x = x + 8
    elseif maker.status == FactoryStatuses.WORKING then
        rsSetColorA(gpu, systemColors.Green)
        gpu:setText(x, y, "WORKING")
        x = x + 7
        rsSetColorA(gpu, systemColors.Normal)
        gpu:setText(x, y, "[Task:")
        x = x + 6
        if maker.taskID == nil then
            rsSetColorA(gpu, systemColors.LightRed)
            gpu:setText(x, y, "?")
            x = x
        else
            rsSetColorA(gpu, systemColors.Purple)
            str = tostring(maker.taskID)
            gpu:setText(x, y, str)
            x = x + string.len(str)
        end
        rsSetColorA(gpu, systemColors.Normal)
        gpu:setText(x, y, "]")
        x = x + 16
    elseif maker.status == FactoryStatuses.IDLE then
        rsSetColorA(gpu, systemColors.Yellow)
        gpu:setText(x, y, "IDLE")
        x = x + 5
    end
end

---@param gpu GPU_T1_C
---@param x number
---@param y number
---@param craftUnit CraftUnitInfo
function printCraftUnitInfo(gpu, x, y, craftUnit)
    local systemColors = scriptInfo.systemColors
    local _x = x
    local str = craftUnit.name
    rsSetColorA(gpu, systemColors.Cyan)
    gpu:setText(x, y, str)
    x = x + string.len(str)
    rsSetColorA(gpu, systemColors.Normal)
    gpu:setText(x, y, ":")
    x = x + 2
    str = craftUnit.comment
    if str == nil then
        str = "None"
    end
    rsSetColorA(gpu, systemColors.Grey)
    gpu:setText(x, y, "(" .. str .. ")")
    x = x + 4 + string.len(str)
    rsSetColorA(gpu, systemColors.Number)
    str = tostring(countAssocTable(craftUnit.recipes))
    gpu:setText(x, y, str)
    x = x + string.len(str) + 1
    rsSetColorA(gpu, systemColors.Normal)
    gpu:setText(x, y, "recipes")
    x = _x
    y = y + 1
    local ly = y
    local lx = x
    local depIndex = 1
    local depCount = 0
    for _,_ in pairs(craftUnit.makers) do
        depCount = depCount + 1
    end
    for _,maker in pairs(craftUnit.makers) do
        rsSetColorA(gpu, TREE_COLOR);
        if depIndex < depCount then
            gpu:setText(x, y, "├")
        else
            gpu:setText(x, y, "└")
        end
        if x > lx then --if y < ly then
            for i = ly + 1, scriptInfo.screenHeight do
                gpu:setText(lx, i, "│")
            end
            for i = 1, y - 1 do
                gpu:setText(x, i, "│")
            end
            ly = -1
        end
        if y - ly > 0 then
            for i = ly + 1, y - 1 do
                gpu:setText(x, i, "│")
            end
        end
        ly = y
        lx = x
        depIndex = depIndex + 1
        printMaker( gpu,x + 2, y, maker)
        x, y = rsadvanceY(x, y, CRAFT_COL_WIDTH)
        computer.skip()
    end
    return x, y
end

function printScreen()
    scriptInfo.gpu = computer.getGPUs()[1]
    --scriptInfo.gpu:setText(1, 1, "╚═════════════════════╝")
    local gpu = scriptInfo.gpu
    if gpu == nil then
        print("No Screen")
        return
    end
    local taskItem = tasks.first
    local x = 0
    local y = 0
    local systemColors = scriptInfo.systemColors
    rsClear(gpu)
    rsSetColorA(gpu, systemColors.Normal);
    gpu:setText(x, y, "Tasks: "); y = y + 1
    while taskItem ~= nil do
        local task = taskItem.value
        if task.parent == nil or task.parent == 0 then
            x, y = printTask2(gpu, x, y, task)
        end
        --y = y + 1
        --x, y = rsadvanceY(x, y, CRAFT_COL_WIDTH)
        --for _,v in pairs(task.dependencies) do
        --    printDependency(x, y, v)
        --    x, y = rsadvanceY(x, y, CRAFT_COL_WIDTH)
        --end

        taskItem = taskItem.next
        if x + CRAFT_COL_WIDTH >= 210 then
            break
        end
    end
    x = 210
    y = 0
    gpu:fill(x, 0, scriptInfo.screenWidth - x, scriptInfo.screenHeight, " ")
    rsSetColorA(gpu, systemColors.Normal);
    gpu:setText(x, y, "Craft units: "); y = y + 1
    local ly = y
    local lx = x
    local depIndex = 1
    local depCount = 0
    for _,_ in pairs(craftUnits) do
        depCount = depCount + 1
    end
    for _,craftUnit in pairs(craftUnits) do
        rsSetColorA(gpu, TREE_COLOR);
        if depIndex < depCount then
            gpu:setText(x, y, "├")
        else
            gpu:setText(x, y, "└")
        end
        if y < ly then
            for i = ly + 1, scriptInfo.screenHeight do
                gpu:setText(lx, i, "│")
            end
            ly = -1
        end
        if y - ly > 0 then
            for i = ly + 1, y - 1 do
                gpu:setText(x, i, "│")
            end
        end
        ly = y
        lx = x
        depIndex = depIndex + 1
        x, y = printCraftUnitInfo(gpu, x + 2, y, craftUnit)
        x = x - 2
        x, y = rsadvanceY(x, y, CRAFT_COL_WIDTH)
    end
    printAssisBox(gpu)
    gpu:flush()
end
--}}}

function countAssocTable(table)
    local c = 0
    for _,_ in pairs(table) do
        c = c + 1
    end
    return c
end

function main()

    ---printArraySmart(t2, 5)

    --initTestPanel()

    initWallPanel()

    initNetwork()

    requestMakers()

    initLowStockQueueing()

    --printArray(stock.Coal, 2)

    schedulePeriodicTask(PeriodicTask.new(function() return scheduler()  end))
    schedulePeriodicTask(PeriodicTask.new( function() printScreen()  end, nil, 1000))

    print( " -- - INIT DONE - - --  ")

    rmessage("System Operational")

    commonMain(0.2, 0.1)
end