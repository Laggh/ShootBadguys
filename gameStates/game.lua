local thisState = {}
sin,cos = math.sin, math.cos

local map = {
    sizeX = 20,
    sizeY = 20
}
for i = 1,20 do
    map[i] = {}
    for ii = 1,20 do
        map[i][ii] = (i+ii*2)%5 == 0
    end
end


local player = {
    x = 20,
    y = 20,
}


local cam = {
    offX = 0,
    offY = 0,
    scale = 50,
}

local projectiles = {

}
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
    newProj = {
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
        x,y = toScreen(v.x,v.y)
        x2,y2 = toScreen(
            v.x-((cos(v.dir) * v.speed * projectileFxSize)),
            v.y-((sin(v.dir) * v.speed * projectileFxSize))
        )

        withColor(1,1,0,1,function ()
            love.graphics.line(x,y,x2,y2)
        end)
    end 
end

function runCam()
    w,h = love.window.getMode()

    cam.offX = player.x -(w/cam.scale)/2
    cam.offY = player.y -(h/cam.scale)/2
end
function toGame(x,y)
    newX = (x/cam.scale)+cam.offX
    newY = (y/cam.scale)+cam.offY
    return newX,newY
end
function toScreen(x,y)
    newX = (x-cam.offX)*cam.scale
    newY = (y-cam.offY)*cam.scale
    return newX,newY
end


function drawMap()
    for ix = 1, map.sizeX do
        for iy = 1, map.sizeY do
            tile = map[ix][iy]
            local mode
            
            if tile == true then
                mode = "fill"
            else
                mode = "line"
            end
            local x,y = toScreen(ix-1,iy-1)
            local w = cam.scale
            local h = cam.scale
            love.graphics.rectangle(mode,x,y,w,h)
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
    runCam()
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
