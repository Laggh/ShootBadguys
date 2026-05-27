local thisState = {}
local t

-- local buttons = {
--     {"Play",function() changeGameState("game","mapa01") end},
--     {"Options",function() changeGameState("mainMenu/options") end},
--     {"Exit",function() love.event.quit() end}
-- }
local scale = 1
local buttons = {
    {name="Play",action=function() changeGameState("game","mapa01") end,x=nil,y=nil,w=nil,h=nil},
    {name="Options",action=function() changeGameState("mainMenu/options") end,x=nil,y=nil,w=nil,h=nil},
    {name="Exit",action=function() love.event.quit() end,x=nil,y=nil,w=nil,h=nil},
}

local function calculateButtonSizes(w,h)
    local buttonHeight = 64
    local buttonSectionHeight = #buttons * (buttonHeight + 16)
    scale = (h*0.8) /  buttonSectionHeight
    scale = math.floor(scale)
    local startY = h - (buttonSectionHeight * scale)
    local y = startY

    for i,button in ipairs(buttons) do
        button.x = 16
        button.y = y
        button.w = 200*scale
        button.h = buttonHeight*scale
        y = y + (buttonHeight + 16)*scale
    end

end
function thisState.load()
    t=0
    calculateButtonSizes(love.graphics.getWidth(),love.graphics.getHeight())
    --changeGameState("game","mapa01")
end 

function thisState.draw()
    local screenW,screenH = love.window.getMode()

    for i,button in ipairs(buttons) do
        local text = button.name
        love.graphics.rectangle("line", button.x, button.y, button.w, button.h)
        love.graphics.print(text, button.x, button.y)
    end

    local width, height = img.logo_full:getDimensions()
    love.graphics.draw(img.logo_full,
        screenW-(16*scale),0+(16*scale),
        0,
        scale,scale,
        width, 0
    )

    






    t = t + love.timer.getDelta()
    withColor(0,0,0,1-t,function ()
        love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight())
    end)
end

function thisState.mousepressed()

end

function thisState.resize(w,h)
    calculateButtonSizes(w,h)
end

return thisState
