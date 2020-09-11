--
-- Created by IntelliJ IDEA.
-- User: Roze
-- Date: 2020-08-22
-- Time: 11:11
-- To change this template use File | Settings | File Templates.
--
screens = {
    gridWidth = 0,
    gridHeight = 0,
    cellWidth = 0,
    cellHeight = 0,
    panels = {}
}


function screens.init(prefix, gridWidth, gridHeight, cellWidth, cellHeight)
    local index = 0
    print("Init Screens; ")
    print(prefix)
    print(gridWidth)
    print(gridHeight)
    print(cellWidth)
    print(cellHeight)
    screens.gridWidth = gridWidth
    screens.gridHeight = gridHeight
    screens.cellWidth = cellWidth
    screens.cellHeight =  cellHeight
    for y = 0,gridHeight - 1,1 do
        for x = 0,gridWidth - 1,1 do
            local gpu = computer.getGPUs()[index + 1]
            local screen = component.proxy(component.findComponent(prefix .. " Screen " .. tostring(index + 1))[1])
            local panel  = {
                reference = screen,
                index = 0,
                x = x * cellWidth,
                y = y * cellHeight,
                w = cellWidth,
                h = cellHeight,
                gpu = gpu
            }
            screens.panels[index] = panel
            gpu:bindScreen(panel.reference)
            gpu:setBackground(0,0,0,0)
            gpu:setsize (cellWidth,cellHeight)
            local screenW,screenH = gpu:getSize()
            panel.screenW = screenW
            panel.screenH = screenH
            gpu:fill(0,0,screenW,screenH," ")
            gpu:setForeground(1,1,1,1)
            print("Screen init done")
            panel.index = index
            index = index + 1
            gpu:flush()
        end
    end
end

function screens:clear()
    for _,v in pairs(screens.panels) do
        v.gpu:fill(0,0,v.screenW,v.screenH," ")
    end
end

function gColumnAdvance(x,y,c)
    y = y + 1
    if y >= screens.cellHeight then
        y = 0
        x = x + c
    end
    return x, y
end

function gHeightEnsure(x,y,c,h)
    y = y + 1
    if y + h >= screens.cellHeight then
        y = 0
        x = x + c
    end
    return x, y
end

function gPrint(x,y,text)
    local _x = math.floor(x / screens.cellWidth)
    local _y = math.floor(y / screens.cellHeight)
    local index = _y * screens.gridWidth + _x
    if screens[index] then
        screens.gpu:setText(x - (_x * screens.cellWidth), y - (_y * screens.cellHeight), text)
    end
end


function screens:dprint(index, x,y, text)
    if x < 0 or y < 0 then
        error("Negative x or y, x="..tostring(x)..", y=" .. tostring(y))
    end
    if screens.panels[index] then
        screens.panels[index].gpu:setText(x, y, text)
    end
end

function screens:print(x, y, text)
    --print(x)
    --print(y)
    --print(text)
    local _x = math.floor(x / screens.cellWidth)
    local _y = math.floor(y / screens.cellHeight)
    local index = _y * screens.gridWidth + _x
    --print ("index: " .. tostring(index))
    --print ("x = "..tostring(x - (_x * screens.cellWidth)))
    --print ("y = "..tostring(y - (_y * screens.cellHeight)))
    if screens.panels[index] then
        screens.panels[index].gpu:setText(x - (_x * screens.cellWidth), y - (_y * screens.cellHeight), text)
    else
        --print("No Screen")
    end
end


function screens:dfill(index, x,y,w,h,c)
    if x < 0 or y < 0 or x + w < 0 or y + h < 0 then
        error("Negative x or y, x="..tostring(x)..", y=" .. tostring(y)..", w=" .. tostring(w)..", h=" .. tostring(h))
    end
    if screens.panels[index] then
        screens.panels[index].gpu:fill(x,y,w,h,c)
    end
end

function screens:fill(x, y, text)
    --print(x)
    --print(y)
    --print(text)
    local _x = math.floor(x / screens.cellWidth)
    local _y = math.floor(y / screens.cellHeight)
    local index = _y * screens.gridWidth + _x
    --print ("index: " .. tostring(index))
    --print ("x = "..tostring(x - (_x * screens.cellWidth)))
    --print ("y = "..tostring(y - (_y * screens.cellHeight)))
    if screens.panels[index] then
        screens.panels[index].gpu:fill(x - (_x * screens.cellWidth),y - (_y * screens.cellHeight),w,h,c)
        --screens.panels[index].gpu:fill(x , y , text)
    else
        --print("No Screen")
    end
end

function screens:listen(callback)
    for _,screen in pairs(screens.panels) do
        registerEvent(screen.gpu, screen, function (instance, event)
            print("Screen event: " .. event)
        end)
        print("Listening on screen ".. tostring(screen.index))
        event.listen(screen.gpu)
        event.listen(screen.reference)
    end
end

function screens:flush()
    for _,v in pairs(screens.panels) do
        v.gpu:flush()
    end
end

function screens:setForeground(r,g,b,a)
    for _,v in pairs(screens.panels) do
        v.gpu:setForeground(r,g,b,a)
    end
end
function screens:dsetForeground(index, r,g,b,a)
    if screens.panels[index] then
        screens.panels[index].gpu:setForeground(r,g,b,a)
    end
end

function screens:setBackground(r,g,b,a)
    for _,v in pairs(screens.panels) do
        v.gpu:setForeground(r,g,b,a)
    end
end
