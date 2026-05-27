local thisState = {}
local t

function thisState.load()
    t = 0
    --changeGameState("game","mapa01")
end 

function thisState.draw()
   
    if t > 3 then
        changeGameState("mainMenu/mainMenu")
    else
        t = t + love.timer.getDelta()

        withColor(1,1,1,t,function()
            love.graphics.setFont(font.big)
            local screenW,screenH = love.window.getMode()
            local textWidth = love.graphics.getFont():getWidth("Made by Laggh")
            local textHeight = love.graphics.getFont():getHeight()

            love.graphics.print("Made by Laggh",(screenW - textWidth) / 2,(screenH - textHeight) / 2)
            love.graphics.setFont(font.small)
        end)



    end
end

function thisState.mousepressed()
    t = math.huge
end

return thisState
