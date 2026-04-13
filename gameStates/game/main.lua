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
local cam = camLib.newCam({
    isCenter = true,
    smooth = true,
})


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

            spread = 0.1,
            shotSpread = 0.1,
            dashSpread = 0.2,
            movementSpread = 0.05,

            speedFactor = 1,
            canAim = true,
            isAuto = false,

            ammo = 12,
            maxAmmo = 12,
            reloadTime = 0.5,
            backupAmmo = 36,
            maxBackupAmmo = 36,
        },
        {
            name = "SMG",
            damage = 30,
            projectileSpeed = 0.35,
            projectilesPerShot = 1,
            fireRate = 12,

            spread = 0.2,
            shotSpread = 0.10,
            dashSpread = 0.2,
            movementSpread = 0.03,

            speedFactor = 1,
            canAim = true,
            isAuto = true,

            ammo = 3000,
            maxAmmo = 30,
            reloadTime = 0.7,
            backupAmmo = 90,
            maxBackupAmmo = 90,
        }
    },
    x = 0,
    y = 0,
    sx = 0,
    sy = 0,
    speed = 0.1,

    spread = 0,
    getSpread = function (self)
        local spread = self.spread
        local weapon = self.weapons[self.selectedWeapon]
        local speed = math.getDistance(self.sx,self.sy,0,0)

        spread = spread + speed * weapon.movementSpread
        if self.isAiming then spread = spread * 0.5 end
        if self.currentAction == "dashing" then spread = spread + weapon.dashSpread end
        

        return spread
    end,
    shootCooldown = 0,

    currentAction = "ready",
    actionDuration = 0,

    canDash = true,
    dashDuration = 0.25,
    dashDelay = 1,
    dashSpeed = 0.18,
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
        if not inArray(self.currentAction,{"dashing","ready"}) then return end
        if self.weapons[self.selectedWeapon].ammo <= 0 then return end
        
        local weapon = self.weapons[self.selectedWeapon]
        weapon.ammo = weapon.ammo - 1
        
        local gmx,gmy = toGame(love.mouse.getPosition())
        local angle = math.getAngle(self.x,self.y,gmx,gmy)


        local projectileAmount = weapon.projectilesPerShot
        
        local movementInfluence = math.getDistance(self.input.move[1],self.input.move[2],0,0) * weapon.movementSpread
        local isMoving = movementInfluence > 0

        self.spread = self.spread + (weapon.shotSpread * (1 + movementInfluence))
        if isMoving then self.spread = self.spread + weapon.movementSpread end

        spread = self:getSpread()
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
            local angle
            if self.input.move[1] == 0 and self.input.move[2] == 0 then
                angle = math.getAngle(self.x,self.y,gmx,gmy)
            else
                angle = math.getAngle(0,0,self.input.move[1],self.input.move[2])
            end
            self.sx = cos(angle)*self.dashSpeed
            self.sy = sin(angle)*self.dashSpeed
        end
    end,

    tick = function(self)
        self:checkInput()
        weapon = self.weapons[self.selectedWeapon]
        self.shootCooldown = math.max(0,self.shootCooldown - love.timer.getDelta())
        self.actionDuration = math.max(0,self.actionDuration - love.timer.getDelta())
        self.currentDashDelay = math.max(0,self.currentDashDelay - love.timer.getDelta())
        self.spread = math.max(
            weapon.spread, 
            self.spread - 0.8*love.timer.getDelta() 
                - (self.spread > 0.6 and 0.6 or 0.1)*love.timer.getDelta() 
                - (self.isAiming and 0.1 or 0)*love.timer.getDelta()
        )

        if self.currentDashDelay == 0 then self.canDash = true end
        
        if self.currentAction == "ready" then
            if self.input.weapon1 then self.selectedWeapon = 1 end
            if self.input.weapon2 then self.selectedWeapon = 2 end
        end

        if self.isGrounded then
            self.sx = 0
            self.sy = 0
            if self.input.aim and self.currentAction == "ready" then 
                self.isAiming = true
            else 
                self.isAiming = false 
            end
            if self.input.dash then
                self:dash()
            end

            local speed = self.speed
            if self.isAiming or self.currentAction == "reloading" then speed = speed * 0.2 end
            if self.input.move[1] == 0 and self.input.move[2] == 0 then speed = 0 end

            self.sx = (self.sx + self.input.move[1]*speed)
            self.sy = (self.sy + self.input.move[2]*speed)
            
            if self.currentAction == "reloading" and self.actionDuration == 0 then
                self.currentAction = "ready"
                local neededAmmo = weapon.maxAmmo - weapon.ammo
                local ammoToLoad = math.min(neededAmmo, weapon.backupAmmo)
                weapon.ammo = weapon.ammo + ammoToLoad
                weapon.backupAmmo = weapon.backupAmmo - ammoToLoad
            end

            if self.input.reload and self.currentAction ~= "reloading" 
                and weapon.ammo < weapon.maxAmmo 
                and weapon.backupAmmo > 0 then

                self.currentAction = "reloading"
                self.actionDuration = weapon.reloadTime
            end
        else
            self.sx = self.sx * 0.99
            self.sy = self.sy * 0.99

            self.currentDashDuration = math.max(0,self.currentDashDuration - love.timer.getDelta())
            if self.currentDashDuration == 0 then
                self.currentAction = "ready"
                self.isGrounded = true
                self.sx = 0
                self.sy = 0
            else

            end
        end

        newX = self.x + self.sx
        newY = self.y + self.sy
        if not checkCollision(newX,self.y) then -- só o X
            self.x = newX
        end
    
        if not checkCollision(self.x,newY) then -- só o Y
            self.y = newY
        end

        local weapon = self.weapons[self.selectedWeapon]
        if (self.input.shootPressed or (self.input.shoot and weapon.isAuto))and self.shootCooldown == 0 then
            self:shoot()
        end
    end,

    draw = function(self)
        withColor(0,0.5,1,1,function ()
            x,y = toScreen(self.x,self.y)

            love.graphics.circle("fill",x,y,cam.scale*0.2)
        end)
        
        --debug spread 
        withColor(0.5,0.5,0.5,0.5, function ()
            local gmx,gmy = toGame(love.mouse.getPosition())
            local angle = math.getAngle(self.x,self.y,gmx,gmy)
            local spread = self:getSpread()
            local x1 = self.x + cos(angle - spread/2)*10.5
            local y1 = self.y + sin(angle - spread/2)*10.5
            local x2 = self.x + cos(angle + spread/2)*10.5
            local y2 = self.y + sin(angle + spread/2)*10.5
            local sx1,sy1 = toScreen(x1,y1)
            local sx2,sy2 = toScreen(x2,y2)
            local px,py = toScreen(self.x,self.y)

            love.graphics.line(px,py,sx1,sy1)
            love.graphics.line(x,y,sx2,sy2)
        end)


        if self.isAiming then
            withColor(1,0,0,0.8,function ()
                local gmx,gmy = toGame(love.mouse.getPosition())
                local angle = math.getAngle(self.x,self.y,gmx,gmy)
                local rx,ry,dist = raycastAngleOptmized(self.x,self.y,angle,25)

                if not rx and not ry then
                    rx = self.x + cos(angle)*25
                    ry = self.y + sin(angle)*25
                end
                if rx and ry then
                    drawPx,drawPy = toScreen(self.x,self.y)
                    drawRx,drawRy = toScreen(rx,ry)

                    love.graphics.line(drawPx,drawPy,drawRx,drawRy)
                end
            end)
        end
    end,

}



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

        --efeito pra impedir a linha do tiro ficar atras do personagem qnd ele atira
        local fxInfluence = v.speed * projectileFxSize
        fxInfluence = math.min(fxInfluence, v.t * v.speed)

        local x2,y2 = toScreen(
            v.x-((cos(v.dir) * fxInfluence)),
            v.y-((sin(v.dir) * fxInfluence))
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

function drawCrosshair()
    local mx,my = love.mouse.getPosition()
    local opening = (player:getSpread()*3)^3 * 15 + 3
    if player:getSpread() < 0.1 then opening = 1 end

    local length = 5


    withColor(1,1,1,1,function ()
        love.graphics.line(mx-opening-length,my,mx-opening,my)
        love.graphics.line(mx+opening,my,mx+opening+length,my)
        love.graphics.line(mx,my-opening-length,mx,my-opening)
        love.graphics.line(mx,my+opening,mx,my+opening+length)
    end)
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

function thisState.load()
    thisState.resize(love.graphics.getDimensions())
end 

function thisState.update()
    local gmx,gmy = toGame(love.mouse.getPosition())
    

    local mouseWeight = 0.5
    if player.isAiming then mouseWeight = 1.2 end
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
    player:draw()
    drawProjectiles()
    drawCrosshair()
    
    str = tostring(love.timer.getFPS()).."\n"

    str = str..string.interpolate("Input:\n move: ${move1}, ${move2}\n dash: ${dash}\n shoot: ${shoot}\n aim: ${aim}\n",{
        move1 = player.input.move[1],
        move2 = player.input.move[2],
        dash = tostring(player.input.dash),
        shoot = tostring(player.input.shoot),
        aim = tostring(player.input.aim),
    })
    local w,h = love.graphics.getDimensions()
    str = str..string.interpolate("\nPlayer:\n x: ${x}\n y: ${y}\n sx: ${sx}\n sy: ${sy}\n isGrounded: ${isGrounded}\n isAiming: ${isAiming}\n shootCooldown: ${shootCooldown}\n action: ${action}\n spread: ${spread}\n",{
        x = player.x,
        y = player.y,
        sx = player.sx,
        sy = player.sy,
        isGrounded = tostring(player.isGrounded),
        isAiming = tostring(player.isAiming),
        shootCooldown = tostring(player.shootCooldown),
        action = player.currentAction,
        spread = tostring(player:getSpread()),
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
