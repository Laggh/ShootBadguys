local thisState = {}
local camLib = require("lib/cam")
local mapLib = require("lib/tilesetHandler")

sin,cos = math.sin, math.cos

local map = mapLib.tiledToTable("map/mapa01.json")
print(json.encode(img.tiles.tilemap))
local tileArr = mapLib.tilesetToArray(img.tiles.tilemap,32,32)



local player = {
    x = 0,
    y = 0,
}

local cam = camLib.newCam({
    isCenter = true,
    smooth = true,
})

local projectiles = {}

function batchCreateProjectiles(_Amount,_X,_Y,_Dir,_Speed,_DirSpread,_SpeedSpread)
    print("batchCreateProjectiles",_Amount)
    _DirSpread = _DirSpread or 0
    _SpeedSpread = _SpeedSpread or 0

    for i = 1,_Amount do
        local dir = _Dir + (math.random()-0.5)*_DirSpread
        local speed = _Speed + (math.random()-0.5)*_SpeedSpread

        newProjectile(_X,_Y,dir,speed)
    end
end
function newProjectile(_X,_Y,_Dir,_Speed,_Data)
    local newProj = {
        x = _X,
        y = _Y,
        dir = _Dir,
        speed = _Speed,
    }

    table.insert(projectiles,newProj)
end
function runProjectiles()
    for i,v in ipairs(projectiles) do
        v.x = v.x + (cos(v.dir) * v.speed)
        v.y = v.y + (sin(v.dir) * v.speed)
    end
end
function drawProjectiles()
    local projectileFxSize = 1

    for i,v in ipairs(projectiles) do
        local x,y = toScreen(v.x,v.y)
        local x2,y2 = toScreen(
            v.x-((cos(v.dir) * v.speed * projectileFxSize)),
            v.y-((sin(v.dir) * v.speed * projectileFxSize))
        )

        withColor(1,1,0,1,function ()
            love.graphics.line(x,y,x2,y2)
        end)
    end 
end


function toGame(x,y)
    return cam:toGame(x,y)
end

function toScreen(x,y)
    return cam:toScreen(x,y)
end


function drawMap()
    for ix = 1, map.width do
        for iy = 1, map.height do
            tile = map.layers[1].data2[ix][iy]
            local x,y = toScreen(ix-1,iy-1)
            local w = cam.scale
            local h = cam.scale

            drawFit(tileArr[tile],x,y,0,w,h)
        end 
    end
end

function drawPlayer()
    withColor(0,0.5,1,1,function ()
        x,y = toScreen(player.x,player.y)

        love.graphics.circle("line",x,y,cam.scale*0.2)
    end)    
end

function thisState.load()
    print(toGame(16,16))
end 

function thisState.update()
    local gmx,gmy = toGame(love.mouse.getPosition())
    
    cam:setTargets({
        {x=player.x, y=player.y, weight=1},
        {x=gmx, y=gmy, weight=0.5},
    })
    cam:tick()
    runProjectiles()
end
function thisState.draw()
    drawMap()
    drawPlayer()
    drawProjectiles()

    withColor(0.5,0.5,0.5,0.1,function ()
        love.graphics.line(0,300,800,300)
        love.graphics.line(400,0,400,600)    
    end)

    love.graphics.print(str,10,10)

end 

function thisState.mousepressed(mx,my,mBtn)


    if mBtn == 1 then
        gmx,gmy = toGame(mx,my)
        batchCreateProjectiles(30,player.x,player.y,math.getAngle(player.x,player.y,gmx,gmy),0.2,0.2,0.2)
    end

    if mBtn == 2 then
        player.x,player.y = toGame(mx,my)
    end
end

return thisState
