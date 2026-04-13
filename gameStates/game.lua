local thisState = {}
local camLib = require("lib/cam")
local mapLib = require("lib/tilesetHandler")

sin,cos = math.sin, math.cos
local keysPressedThisFrame = {}

local map = mapLib.tiledToTable("map/mapa01.json")
map.collision = {}
for i,v in ipairs(map.properties[1].value) do
    print("colisao",v.value)
    map.collision[i] = v.value
end
print(json.encode(img.tiles.tilemap))
local tileArr = mapLib.tilesetToArray(img.tiles.tilemap,32,32)

function checkCollision(x,y)
    local tileX = math.floor(x)+1
    local tileY = math.floor(y)+1

    if tileX < 1 or tileY < 1 or tileX > map.width or tileY > map.height then return true end

    local tile = map.layers[1].data2[tileX][tileY]
    return inArray(tile,map.collision)
end


function raycastAngleOptmized(_X,_Y,_Angle,_MaxDist)
    local tileX,tileY = math.floor(_X)+1, math.floor(_Y)+1
    local sx,sy = cos(_Angle), sin(_Angle)
    local dirX = (sx > 0 and 1) or (sx < 0 and -1) or 0
    local dirY = (sy > 0 and 1) or (sy < 0 and -1) or 0

    if dirX == 0 and dirY == 0 then return nil,nil,_MaxDist end

    local deltaDistX = (dirX ~= 0) and math.abs(1/sx) or math.huge
    local deltaDistY = (dirY ~= 0) and math.abs(1/sy) or math.huge

    local nextBoundaryX = (dirX > 0) and tileX or (tileX - 1)
    local nextBoundaryY = (dirY > 0) and tileY or (tileY - 1)

    local tMaxX = (dirX ~= 0) and ((nextBoundaryX - _X) / sx) or math.huge
    local tMaxY = (dirY ~= 0) and ((nextBoundaryY - _Y) / sy) or math.huge

    local dist = 0

    while dist <= _MaxDist do
        if tileX < 1 or tileY < 1 or tileX > map.width or tileY > map.height then return nil,nil,_MaxDist end

        local tile = map.layers[1].data2[tileX][tileY]
        if inArray(tile,map.collision) then
            return _X + sx*dist, _Y + sy*dist, dist
        end

        if tMaxX < tMaxY then
            tileX = tileX + dirX
            dist = tMaxX
            tMaxX = tMaxX + deltaDistX
        else
            tileY = tileY + dirY
            dist = tMaxY
            tMaxY = tMaxY + deltaDistY
        end
    end

    return nil,nil,_MaxDist
end

local player = {
    x = 0,
    y = 0,
    sx = 0,
    sy = 0,
    speed = 0.1,

    canDash = true,
    dashDuration = 0.4,
    dashDelay = 1.4,
    dashSpeed = 0.2,
    currentDashDuration = 0,
    currentDashDelay = 0,

    isGrounded = true,
    isAiming = false,
}

local cam = camLib.newCam({
    isCenter = true,
    smooth = true,
})

local projectiles = {}

function batchCreateProjectiles(_Amount,_X,_Y,_Dir,_Speed,_DirSpread,_SpeedSpread)
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
        t = 0
    }

    table.insert(projectiles,newProj)
end
function runProjectiles()
    for i = #projectiles,1,-1 do
        v = projectiles[i]
        v.x = v.x + (cos(v.dir) * v.speed)
        v.y = v.y + (sin(v.dir) * v.speed)
        v.t = v.t + 1

        
        if v.t > 300 or checkCollision(v.x,v.y) then
            table.remove(projectiles,i)
        end
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

function runPlayer()
    if player.isGrounded then
        player.currentDashDelay = math.max(0,player.currentDashDelay - love.timer.getDelta())
        if player.currentDashDelay == 0 then
            player.canDash = true
        end

        local walkVec = {0,0}

        if love.mouse.isDown(2) 
        then player.isAiming = true
        else player.isAiming = false end
        if love.keyboard.isDown("w") then walkVec[2] = walkVec[2] - 1 end
        if love.keyboard.isDown("s") then walkVec[2] = walkVec[2] + 1 end
        if love.keyboard.isDown("a") then walkVec[1] = walkVec[1] - 1 end
        if love.keyboard.isDown("d") then walkVec[1] = walkVec[1] + 1 end
        if keysPressedThisFrame["space"] and player.canDash then
            player.canDash = false
            player.isGrounded = false
            player.isAiming = false
            player.currentDashDuration = player.dashDuration
            player.currentDashDelay = player.dashDelay

            gmx,gmy = toGame(love.mouse.getPosition())
            local angle = math.getAngle(player.x,player.y,gmx,gmy)
            player.sx = cos(angle)*player.dashSpeed
            player.sy = sin(angle)*player.dashSpeed
        end




        local angle = math.getAngle(0,0,walkVec[1],walkVec[2])
        local speed = player.speed
        if player.isAiming then speed = speed * 0.5 end
        if walkVec[1] == 0 and walkVec[2] == 0 then speed = 0 end
        local newX = player.x + cos(angle)*speed
        local newY = player.y + sin(angle)*speed
        if not checkCollision(newX,player.y) then -- só o X
            player.x = newX
        end
    
        if not checkCollision(player.x,newY) then -- só o Y
            player.y = newY
        end
    else
        player.currentDashDuration = math.max(0,player.currentDashDuration - love.timer.getDelta())
        if player.currentDashDuration == 0 then
            player.isGrounded = true
            player.sx = 0
            player.sy = 0
        else
            player.sx = player.sx * 0.98
            player.sy = player.sy * 0.98

            local newX = player.x + player.sx
            local newY = player.y + player.sy

            if not checkCollision(newX,player.y) then -- só o X
                player.x = newX
            end
        
            if not checkCollision(player.x,newY) then -- só o Y
                player.y = newY
            end
        end
    end
end

function thisState.load()

end 

function thisState.update()
    local gmx,gmy = toGame(love.mouse.getPosition())
    

    local mouseWeight = 0.5
    if player.isAiming then mouseWeight = 2 end
    cam:setTargets({
        {x=player.x, y=player.y, weight=1},
        {x=gmx, y=gmy, weight=mouseWeight},
    })
    cam:tick()
    runProjectiles()
    runPlayer()
    keysPressedThisFrame = {}
end
function thisState.draw()
    drawMap()
    drawPlayer()
    drawProjectiles()

    if player.isAiming then
        withColor(0,1,0,0.5,function ()
            local gmx,gmy = toGame(love.mouse.getPosition())
            local angle = math.getAngle(player.x,player.y,gmx,gmy)
            local rx,ry,dist = raycastAngleOptmized(player.x,player.y,angle,25)

            if not rx and not ry then
                rx = player.x + cos(angle)*25
                ry = player.y + sin(angle)*25
            end
            if rx and ry then
                drawPx,drawPy = toScreen(player.x,player.y)
                drawRx,drawRy = toScreen(rx,ry)

                love.graphics.line(drawPx,drawPy,drawRx,drawRy)
            end
        end)
    end
end 

function thisState.mousepressed(mx,my,mBtn)


    if mBtn == 1 then
        gmx,gmy = toGame(mx,my)
        batchCreateProjectiles(30,player.x,player.y,math.getAngle(player.x,player.y,gmx,gmy),0.2,0.2,0.2)
    end

    if mBtn == 3 then
        player.x,player.y = toGame(mx,my)
    end
end

function thisState.keypressed(key)
    if key == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen())
    end 

    keysPressedThisFrame[key] = true
end

return thisState
