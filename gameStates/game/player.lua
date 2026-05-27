local WEAPONS = require("gamestates/game/weapons")

local function getPlayer(game) 
    local startPosObj = game.map:searchForObject(3,"playerStart")
    if not startPosObj then
        error("Player start position not found in game.map! Please add an object with type 'playerStart' in layer 3.")
    end
    local startX = startPosObj.x / 32
    local startY = startPosObj.y / 32

    local player = {
        health = 100,
        maxHealth = 100,

        selectedWeapon = 1,
        weapons = {
            copyOf(WEAPONS.shotgun),
            copyOf(WEAPONS.smg),
        },
        x = startX,
        y = startY,
        sx = 0,
        sy = 0,
        speed = 0.1,
        size = 0.4,

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

            self.input.dash = game.keysPressedThisFrame["space"] == true
            self.input.shoot = love.mouse.isDown(1)
            self.input.shootPressed = game.keysPressedThisFrame["mouse1"] == true
            self.input.aim = love.mouse.isDown(2)
            self.input.weapon1 = game.keysPressedThisFrame["1"] == true
            self.input.weapon2 = game.keysPressedThisFrame["2"] == true
            self.input.reload = game.keysPressedThisFrame["r"] == true
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
            local projectileData = {
                team = "player",
                damage = weapon.damage,
            }
            batchCreateProjectiles(projectileAmount,self.x,self.y,angle,weapon.projectileSpeed,spread,0.05,projectileData)
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
                self.sx = cos(angle)*self.dashSpeed*(self.weapons[self.selectedWeapon].speedFactor or 1)
                self.sy = sin(angle)*self.dashSpeed*(self.weapons[self.selectedWeapon].speedFactor or 1)
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

                local speed = self.speed * (weapon.speedFactor or 1)
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

                love.graphics.circle("fill",x,y,game.cam.scale*0.2)
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
                    local rx,ry,dist = raycastAngleMap(self.x,self.y,angle,25)

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
    return player
end

return getPlayer