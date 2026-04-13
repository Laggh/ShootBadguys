-- Made by Laggh
-- Dependencies: json.lua (stored in the variable 'json')

local API = {}

-- Transform a tileset into an array of tile images
-- (Tileset, tileWidth, tileHeight) -> [img1, img2, img3, ...]
function API.tilesetToArray(tileset, tileWidth, tileHeight)
    local tileArray = {}

    local tilesetWidth = tileset:getWidth()
    local tilesetHeight = tileset:getHeight()
    
    local tilesetWidth = tilesetWidth / tileWidth
    local tilesetHeight = tilesetHeight / tileHeight

    local tileCount = 1
    for y = 0, tilesetHeight - 1 do
        for x = 0, tilesetWidth - 1 do
            local newCanvas = love.graphics.newCanvas(tileWidth, tileHeight)
            love.graphics.setCanvas(newCanvas)
            love.graphics.draw(tileset, -x * tileWidth, -y * tileHeight)
            love.graphics.setCanvas()
            tileArray[tileCount] = newCanvas
            tileCount = tileCount + 1
        end
    end
    return tileArray
end

-- Transform an array of tile images into a tileset
-- (tileArray[], tileWidth, tileHeight) -> tileset (canvas)
function API.ArrayToTileset(tileArray, tileWidth, tileHeight)
    local tileset = love.graphics.newCanvas(tileWidth * #tileArray, tileHeight)
    love.graphics.setCanvas(tileset)
    for i = 1, #tileArray do
        love.graphics.draw(tileArray[i], (i - 1) * tileWidth, 0)
    end
    love.graphics.setCanvas()
    return tileset
end

local function _collapseProperty(property)
    print("colapsando",json.encode(property))
    local type = property.type
    local value = property.value
    local name = property.name

    if inArray(type, {"string", "float", "int", "bool"}) then
        return name, value
    end

    if type == "color" then
        local r,g,b,a = strToRGB(value)
        return name, {r,g,b,a}
    end

    if type == "list" then
        local list = {}
        local index = 1
        for i,v in ipairs(value) do
            vName, vValue = _collapseProperty(v)
            list[index] = vValue
            index = index + 1
        end


        return name, list
    end
end

-- Transform a .tmj file into a and creates a table with the data called 'data2', the data is in the format 'data[y][x]'
-- (file) -> table
function API.tiledToTable(file,doAddFunctions)
    if not json then
        error("json library not fount, please require it or put it in the variable 'json'")
    end
    if not love.filesystem.getInfo(file) then
        error("File not found")
    end

    local file = love.filesystem.read(file)
    local table = json.decode(file)

    for i,v in ipairs(table.layers) do
        if v.type == "tilelayer" then

            v.tiles = {} --data but in a 2d table instead of a 1d table
            for i = 1, #v.data do
                if not v.tiles[math.ceil(i / v.width)] then
                    v.tiles[math.ceil(i / v.width)] = {}
                end
                v.tiles[math.ceil(i / v.width)][i % v.width == 0 and v.width or i % v.width] = v.data[i]
            end
        end
        if v.type == "objectgroup" then
            --print("Object group found, skipping for now",v.name)
            for ii,vv in ipairs(v.objects) do
                for iii,vvv in ipairs(vv.properties) do
                    local name, value = _collapseProperty(vvv)
                    vv[name] = value
                end
            end
        end
    end

    if doAddFunctions then
        table.getLayer = function(nameOrId)
            if type(nameOrId) == "number" then
                return table.layers[nameOrId]
            end
            for i,v in ipairs(table.layers) do
                if v.name == nameOrId then
                    return v
                end
            end
            return nil
        end

        table.drawTileLayer = function(layer, tileImages, cam)
            local toScreen
            if cam then
                toScreen = function(x,y)
                    return cam:toScreen(x,y)
                end
            else
                toScreen = function(x,y)
                    return x*30,y*30
                end
            end
            if type(layer) ~= "table" then
                layer = table.getLayer(layer)
            end
            if not layer then
                error(strJoin("Layer not found: ", layer))
            end
            
            local strTint = layer.tintColor --No formato #RRGGBB
            local r,g,b = strToRGB(strTint)
            local a = layer.opacity or 1
            
            withColor(r,g,b,a,function()
                for iy = 1, #layer.tiles do
                    for ix = 1, #layer.tiles[iy] do
                        local tileId = layer.tiles[iy][ix]
                        local x,y = toScreen(ix - 1, iy - 1)
                        if tileId ~= 0 then
                            drawFit(tileImages[tileId], x, y,0, cam.scale, cam.scale)
                        end
                    end
                end
            end)
        end

        table.tileAt = function(layerOrX, x, y)
            local layer = layerOrX

            if y == nil then
                y = x
                x = layerOrX
                layer = table.getLayer(2)
            elseif type(layerOrX) ~= "table" and type(layerOrX) ~= "number" then
                layer = table.getLayer(2)
            elseif type(layerOrX) == "number" and x and y then
                layer = table.getLayer(layerOrX)
            end

            if not layer then
                error(strJoin("Layer not found: ", tostring(layerOrX)))
            end

            if not layer.tiles or not layer.tiles[y] then
                return nil
            end

            return layer.tiles[y][x]
        end
    end


    return table
end

return API