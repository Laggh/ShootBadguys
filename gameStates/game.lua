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
    health = 100,

    selectedWeapon = 1,
    weapons = {
        {
            name = "Pistol",
            damage = 60,
            projectileSpeed = 0.4,
            projectilesPerShot = 1,
            fireRate = 4,
            spread = 0.03,
            speedFactor = 1,
            canAim = true,
            isAuto = false,

            ammo = 12,
            maxAmmo = 12,
            reloadTime = 1.5,
            backupAmmo = 36,
            maxBackupAmmo = 36,
        },
        {

        }
    },
    x = 0,
    y = 0,
    sx = 0,
    sy = 0,
    speed = 0.1,

    shootCooldown = 0,

    currentAction = "ready",
    actionDuration = 0,

    canDash = true,
    dashDuration = 0.4,
    dashDelay = 1.4,
    dashSpeed = 0.2,
    currentDashDuration = 0,
    currentDashDelay = 0,

    isGrounded = true,
    isAiming = false,

    input = {
        move = {0,0},
        dash = false,
        shoot = false,
        shootPressed = false,
        aim = false,
        weapon1 = false,
        weapon2 = false,
        reload = false,
    },

    checkInput = function(self)
        self.input.move = {0,0}
        if love.keyboard.isDown("w") then self.input.move[2] = self.input.move[2] - 1 end
        if love.keyboard.isDown("s") then self.input.move[2] = self.input.move[2] + 1 end
        if love.keyboard.isDown("a") then self.input.move[1] = self.input.move[1] - 1 end
        if love.keyboard.isDown("d") then self.input.move[1] = self.input.move[1] + 1 end

        local angle, dist = math.angleDist(0,0,self.input.move[1],self.input.move[2])
        dist = math.min(dist,1)
        self.input.move[1],self.input.move[2] = cos(angle)*dist, sin(angle)*dist

        self.input.dash = keysPressedThisFrame["space"] == true
        self.input.shoot = love.mouse.isDown(1)
        self.input.shootPressed = keysPressedThisFrame["mouse1"] == true
        self.input.aim = love.mouse.isDown(2)
        self.input.weapon1 = keysPressedThisFrame["1"] == true
        self.input.weapon2 = keysPressedThisFrame["2"] == true
        self.input.reload = keysPressedThisFrame["r"] == true
    end,

    shoot = function(self)
        if self.shootCooldown > 0 then return end
        if self.currentAction ~= "ready" then return end
        if self.weapons[self.selectedWeapon].ammo <= 0 then return end
        
        local weapon = self.weapons[self.selectedWeapon]
        weapon.ammo = weapon.ammo - 1
        
        local gmx,gmy = toGame(love.mouse.getPosition())
        local angle = math.getAngle(self.x,self.y,gmx,gmy)


        local projectileAmount = weapon.projectilesPerShot
        local spread = weapon.spread

        batchCreateProjectiles(projectileAmount,self.x,self.y,angle,weapon.projectileSpeed,spread,0.05)
        self.shootCooldown = 1 / self.weapons[self.selectedWeapon].fireRate

    end,

    dash = function(self)
        if self.canDash then
            self.currentAction = "dashing"
            self.canDash = false
            self.isGrounded = false
            self.isAiming = false
            self.currentDashDuration = self.dashDuration
            self.currentDashDelay = self.dashDelay

            gmx,gmy = toGame(love.mouse.getPosition())
            local angle = math.getAngle(self.x,self.y,gmx,gmy)
            self.sx = cos(angle)*self.dashSpeed
            self.sy = sin(angle)*self.dashSpeed
        end
    end,

    tick = function(self)
        self:checkInput()
        self.shootCooldown = math.max(0,self.shootCooldown - love.timer.getDelta())
        if self.isGrounded then
            self.currentDashDelay = math.max(0,self.currentDashDelay - love.timer.getDelta())
            if self.currentDashDelay == 0 then
                self.canDash = true
            end
            if self.input.aim then 
                self.isAiming = true
            else 
                self.isAiming = false 
            end
            if self.input.dash then
                self:dash()
            end

            newX = self.x + self.input.move[1]*self.speed
            newY = self.y + self.input.move[2]*self.speed
            local speed = self.speed
            if self.isAiming or self.currentAction == "reloading" then speed = speed * 0.5 end
            if self.input.move[1] == 0 and self.input.move[2] == 0 then speed = 0 end
            if not checkCollision(newX,self.y) then -- só o X
                self.x = newX
            end
        
            if not checkCollision(self.x,newY) then -- só o Y
                self.y = newY
            end

            
            if self.input.shootPressed and self.shootCooldown == 0 then
                self:shoot()
            end
        else
            self.currentDashDuration = math.max(0,self.currentDashDuration - love.timer.getDelta())
            if self.currentDashDuration == 0 then
                self.currentAction = "ready"
                self.isGrounded = true
                self.sx = 0
                self.sy = 0
            else
                self.sx = self.sx * 0.98
                self.sy = self.sy * 0.98

                local newX = self.x + self.sx
                local newY = self.y + self.sy

                if not checkCollision(newX,self.y) then -- só o X
                    self.x = newX
                end
            
                if not checkCollision(self.x,newY) then -- só o Y
                    self.y = newY
                end
            end
        end
    end
}

local cam = camLib.newCam({
    isCenter = true,
    smooth = true,
})

local projectiles = {}

function batchCreateProjectiles(_Amount,_X,_Y,_Dir,_Speed,_DirSpread,_SpeedSpread,_Data)
    _DirSpread = _DirSpread or 0
    _SpeedSpread = _SpeedSpread or 0

    for i = 1,_Amount do
        local dir = _Dir + (math.random()-0.5)*_DirSpread
        local speed = _Speed + (math.random()-0.5)*_SpeedSpread

        newProjectile(_X,_Y,dir,speed,_Data)
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


function thisState.load()
    thisState.resize(love.graphics.getDimensions())
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
    player:tick()
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
    str = tostring(love.timer.getFPS()).."\n"

    str = str..string.interpolate("Input:\n move: ${move1}, ${move2}\n dash: ${dash}\n shoot: ${shoot}\n aim: ${aim}\n",{
        move1 = player.input.move[1],
        move2 = player.input.move[2],
        dash = tostring(player.input.dash),
        shoot = tostring(player.input.shoot),
        aim = tostring(player.input.aim),
    })
    local w,h = love.graphics.getDimensions()
    str = str..string.interpolate("\nPlayer:\n x: ${x}\n y: ${y}\n sx: ${sx}\n sy: ${sy}\n isGrounded: ${isGrounded}\n isAiming: ${isAiming}\n shootCooldown: ${shootCooldown}\n action: ${action}\n",{
        x = player.x,
        y = player.y,
        sx = player.sx,
        sy = player.sy,
        isGrounded = tostring(player.isGrounded),
        isAiming = tostring(player.isAiming),
        shootCooldown = tostring(player.shootCooldown),
        action = player.currentAction,
        camScale = tostring(cam.scale),
        xTiles = tostring(w / cam.scale),
        yTiles = tostring(h / cam.scale),
    })

    str = str..string.interpolate("\nWeapons:\n selected: ${selected}\n ammo: ${ammo}/${maxAmmo}\n backupAmmo: ${backupAmmo}/${maxBackupAmmo}",{
        selected = player.weapons[player.selectedWeapon].name,
        ammo = player.weapons[player.selectedWeapon].ammo,
        maxAmmo = player.weapons[player.selectedWeapon].maxAmmo,
        backupAmmo = player.weapons[player.selectedWeapon].backupAmmo,
        maxBackupAmmo = player.weapons[player.selectedWeapon].maxBackupAmmo,
    })

    love.graphics.print(str,10,10)
end 

function thisState.mousepressed(mx,my,mBtn)
    if mBtn == 3 then
        player.x,player.y = toGame(mx,my)
    end
    keysPressedThisFrame["mouse"..mBtn] = true
end

function thisState.keypressed(key)
    if key == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen())
    end 

    keysPressedThisFrame[key] = true
end

function thisState.resize(w,h)
    local min = math.min(w,h)
    local max = math.max(w,h)

    cam.scale = (min / 15) + ((max - min) / 15)*0.5

    
end
return thisState
