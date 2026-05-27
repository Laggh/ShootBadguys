function _getGui(game)
    local gui = {}

    function gui.debugDraw(self)
        str = tostring(love.timer.getFPS()).."\n"
        str = str..string.interpolate("Input:\n move: ${move1}, ${move2}\n dash: ${dash}\n shoot: ${shoot}\n aim: ${aim}\n",{
            move1 = game.player.input.move[1],
            move2 = game.player.input.move[2],
            dash = tostring(game.player.input.dash),
            shoot = tostring(game.player.input.shoot),
            aim = tostring(game.player.input.aim),
        })
        local w,h = love.graphics.getDimensions()
        str = str..string.interpolate("\nPlayer:\n hp: ${hp}\n x: ${x}\n y: ${y}\n sx: ${sx}\n sy: ${sy}\n isGrounded: ${isGrounded}\n isAiming: ${isAiming}\n shootCooldown: ${shootCooldown}\n action: ${action}\n spread: ${spread}\n",{
            hp = game.player.health,
            x = game.player.x,
            y = game.player.y,
            sx = game.player.sx,
            sy = game.player.sy,
            isGrounded = tostring(game.player.isGrounded),
            isAiming = tostring(game.player.isAiming),
            shootCooldown = tostring(game.player.shootCooldown),
            action = game.player.currentAction,
            spread = tostring(game.player:getSpread()),
            camScale = tostring(game.cam.scale),
            xTiles = tostring(w / game.cam.scale),
            yTiles = tostring(h / game.cam.scale),
        })

        str = str..string.interpolate("\nWeapons:\n selected: ${selected}\n ammo: ${ammo}/${maxAmmo}\n backupAmmo: ${backupAmmo}/${maxBackupAmmo}",{
            selected = game.player.weapons[game.player.selectedWeapon].name,
            ammo = game.player.weapons[game.player.selectedWeapon].ammo,
            maxAmmo = game.player.weapons[game.player.selectedWeapon].maxAmmo,
            backupAmmo = game.player.weapons[game.player.selectedWeapon].backupAmmo,
            maxBackupAmmo = game.player.weapons[game.player.selectedWeapon].maxBackupAmmo,
        })

        local gmx,gmy = toGame(love.mouse.getPosition())
        str = str..string.interpolate("\nTileAtMouse: \n (${tileX},${tileY})\n collision: ${collision}\n floor:${floor}\n wall:${wall}",{
            tileX = math.floor(gmx)+1,
            tileY = math.floor(gmy)+1,
            collision = tostring(checkCollision(gmx,gmy)),
            floor = tostring(game.map:tileAt(1, math.floor(gmx)+1, math.floor(gmy)+1)),
            wall = tostring(game.map:tileAt(2, math.floor(gmx)+1, math.floor(gmy)+1)),
        })
            

        love.graphics.print(str,10,10) 
    end

    function gui.drawHealthBar(self)
        local barWidth = 200
        local barHeight = 30
        
        local screenW,screenH = love.window.getMode()
        local x = screenW - barWidth - 20
        local y = screenH - barHeight - 20
        local healthPercent = game.player.health / game.player.maxHealth
        if healthPercent < 0 then healthPercent = 0 end
        local internalBarWidth = barWidth * healthPercent

        local r,g,b = 0,0,0
        if healthPercent > 0.8 then
            r = 0
            g = 1
            b = 0
        elseif healthPercent > 0.5 then
            r = 1 - (healthPercent - 0.5) * 5
            g = 1
            b = 0
        else
            r = 1
            g = healthPercent * 2
            b = 0
        end


        withColor(0,0,0,0.5,function()
            love.graphics.rectangle("fill", x-5, y-5, barWidth+10, barHeight+10)
        end)
        withColor(r,g,b,1,function()
            love.graphics.rectangle("fill", x, y, internalBarWidth, barHeight)
        end)
        withColor(1,1,1,1,function()
            love.graphics.rectangle("line", x, y, barWidth, barHeight)
        end)
        
    end


    function gui.draw(self)
        self:debugDraw()
        self:drawHealthBar()

    end



    return gui
end



return _getGui