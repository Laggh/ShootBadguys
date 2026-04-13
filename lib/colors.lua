local lib = {}

---Converts HSV color values to RGB color values
---@param hue number (0 to 1)
---@param saturation number (0 to 1)
---@param value number (0 to 1)
---@return number red (0 to 1)
---@return number green (0 to 1)
---@return number blue (0 to 1)
function HSVtoRGB(hue, saturation, value)
    local red, green, blue

    -- Integer part of the hue multiplied by 6. Used to determine the color sector.
    local i = math.floor(hue * 6)
    -- Fractional part of the hue multiplied by 6. Used to interpolate between color values.
    local f = hue * 6 - i
    -- Value adjusted by saturation. Represents the color intensity when the hue is at its minimum.
    local p = value * (1 - saturation)
    -- Value adjusted by saturation and fractional part. Represents the color intensity when the hue is decreasing.
    local q = value * (1 - f * saturation)
    -- Value adjusted by saturation and fractional part. Represents the color intensity when the hue is increasing.
    local t = value * (1 - (1 - f) * saturation)

    i = i % 6
    if i == 0 then red, green, blue = value, t, p
    elseif i == 1 then red, green, blue = q, value, p
    elseif i == 2 then red, green, blue = p, value, t
    elseif i == 3 then red, green, blue = p, q, value
    elseif i == 4 then red, green, blue = t, p, value
    elseif i == 5 then red, green, blue = value, p, q
    end

    return red, green, blue
end

function strToRGB(str)
    if not str then return 1,1,1 end

    if str:sub(1,1) == "#" then
        str = str:sub(2)
    end

    if #str == 6 then
        str = str .. "ff"
    end


    local r = tonumber(str:sub(1,2), 16) / 255
    local g = tonumber(str:sub(3,4), 16) / 255
    local b = tonumber(str:sub(5,6), 16) / 255
    local a = tonumber(str:sub(7,8), 16) / 255
    return r,g,b,a
end
if love.graphics then
    ---Sets the current drawing color using HSV values
    function love.graphics.setColorHSV(hue, saturation, value, alpha)
        local red, green, blue = HSVtoRGB(hue, saturation, value)
        love.graphics.setColor(red, green, blue, alpha)
    end

end

return lib