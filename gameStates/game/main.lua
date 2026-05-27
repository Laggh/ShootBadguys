local thisState = {}
local TICKS_PER_SECOND = 75
local camLib = require("lib/cam")
local mapLib = require("lib/tilesetHandler")
local WEAPONS = require("gamestates/game/weapons")

local getPlayer = require("gameStates/game/player")

local getGui = require("gameStates/game/gui")

sin,cos = math.sin, math.cos

local game = {}


function checkCollision(x,y)
    local tileX = math.floor(x)+1
    local tileY = math.floor(y)+1

    if tileX < 1 or tileY < 1 or tileX > game.map.width or tileY > game.map.height then return true end

    local tile = game.map:tileAt(tileX, tileY)
    return tile ~= 0
end

function raycastAngleMap(_X,_Y,_Angle,_MaxDist)
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
        if tileX < 1 or tileY < 1 or tileX > game.map.width or tileY > game.map.height then return nil,nil,_MaxDist end

        local tile = game.map:tileAt(tileX, tileY)
        if tile ~= 0 then
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

    return nil,nil,-1
end

function raycastAngleTable(_X,_Y,_Angle,_MaxDist,_Table)
    local x,y = _X,_Y
    local sx,sy = cos(_Angle), sin(_Angle)
    local stepSize = 0.1
    local dist = 0

    while dist <= _MaxDist do
        x = x + sx * stepSize
        y = y + sy * stepSize

        for i,v in ipairs(_Table) do
            if math.getDistance(x,y,v.x,v.y) < v.size/2 then
                return x,y,dist,i
            end
        end

        dist = dist + stepSize
    end

    return nil,nil,-1,nil
end

function getMapAndTileArr(mapName)
    local map = mapLib.tiledToTable(strJoin("map/",mapName,".json"),true)
    map.collision = {}
    for i,v in ipairs(map.properties.collision) do
        print("colisao",v)
        map.collision[i] = v
    end

    local tileArr = mapLib.tilesetToArray(img.tiles.tilemap,32,32)
    return map, tileArr
end

function checkEnemyCollisions(x,y)
    for i,v in ipairs(game.enemies) do
        if math.getDistance(x,y,v.x,v.y) < v.size/2 then
            return i
        end
    end
    return nil
end

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
        t = 0,
        data = _Data or {},
    }

    table.insert(game.projectiles,newProj)
end
function runProjectiles()
    for i = #game.projectiles,1,-1 do
        v = game.projectiles[i]
        v.x = v.x + (cos(v.dir) * v.speed)
        v.y = v.y + (sin(v.dir) * v.speed)
        v.t = v.t + 1

        
        if v.t > 300 or checkCollision(v.x,v.y) then
            table.remove(game.projectiles,i)
        end
        if v.data.team == "player" then
            local enemyHit = checkEnemyCollisions(v.x,v.y)
            if enemyHit then
                local enemy = game.enemies[enemyHit]
                enemy.health = enemy.health - v.data.damage
                if enemy.health <= 0 then
                    table.remove(game.enemies, enemyHit)
                end
                table.remove(game.projectiles,i)
            end
        end


        if v.data.team == "enemy" then
            local distToPlayer = math.getDistance(v.x,v.y,game.player.x,game.player.y)
            if distToPlayer < game.player.size/2 then
                game.player.health = game.player.health - v.data.damage
                table.remove(game.projectiles,i)
            end
        end
    end
end

function drawProjectiles()
    local projectileFxSize = 1

    for i,v in ipairs(game.projectiles) do
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

function getEnemies()
    for i,v in ipairs(game.map:searchForObject(3,"enemy",true)) do
        if v.type == "enemy" then
            table.insert(game.enemies,{
                t=0,
                x = v.x/32,
                y = v.y/32,
                size = 0.6,
                health = v.properties.health or 100,

                alertPercentage = 0, -- 0 to 1, 1 - atirando
                visionRange = v.properties.visionRange or 50,
                visionCone = v.properties.visionCone or math.pi*2,
                direction = v.properties.direction or 0,

                _StoredRaycastResult = nil,
                weapon = copyOf(WEAPONS[v.properties.weapon] or WEAPONS.pistol),

                raycastCheck = function (self)
                    local angleToPlayer = math.getAngle(self.x,self.y,game.player.x,game.player.y)
                    local distToPlayer = math.getDistance(self.x,self.y,game.player.x,game.player.y)
                    
                    local rx,ry,rayDist = raycastAngleMap(self.x,self.y,angleToPlayer,self.visionRange)
                    
                    local raycastResult = self._StoredRaycastResult or {}
                    if rayDist < distToPlayer or rayDist == -1 then
                            raycastResult.playerVisible = false
                    else
                            raycastResult.playerVisible = true
                            raycastResult.position = {rx,ry}
                            raycastResult.angleToPlayer = angleToPlayer
                            raycastResult.distToPlayer = distToPlayer
                    end  
                    self._StoredRaycastResult = raycastResult
                    
                    local FRAMES_PER_RAYCAST = 5
                    local increaseAlertAmount = 0.01 * FRAMES_PER_RAYCAST
                    if self._StoredRaycastResult.playerVisible then
                        self.alertPercentage = math.min(2, self.alertPercentage + increaseAlertAmount)
                    else
                        self.alertPercentage = math.max(0, self.alertPercentage - increaseAlertAmount)
                    end    
                end,

                shoot = function(self, angle)
                    if not self._StoredRaycastResult then return end

                    local angle = self._StoredRaycastResult.angleToPlayer
                    local projectileData = {
                        team = "enemy",
                        damage = math.floor(self.weapon.damage / 3),
                    }
                    batchCreateProjectiles(1,self.x,self.y,angle,self.weapon.projectileSpeed/2,self.weapon.spread*2,0,projectileData)
                end,
                
                --[[
                    TODO():
                    - melhorar o sistema de alerta
                    - fazer os bots andares
                    - adicionar mais função nos bots
                    - fazer os bots terem sistema de input tipo o player, facilitando tudo no futuro
                    -> pensar numa maneira de botar a logica de cada coisa em um arquivo
                    talvez um objeto `game` onde fica tudo, acho interessante
                    - funções `:onXXXXX` para as coisas

                    - suporte para touch e controle
                        - mudar a mira do mouse para um sistema que aceita ou mouse ou {x,y}


                    - talvez adicionar suporte para modelos, deve ser chato mas talvez eu adicione
                ]]
                
                


            })
        end
    end
    return game.enemies
end

function runEnemies()
    local FRAMES_PER_RAYCAST = 5
    for i,v in ipairs(game.enemies) do
        v.t = v.t + 1
        local doRaycastCheck = v.t % FRAMES_PER_RAYCAST == 0
        if doRaycastCheck then
            v:raycastCheck()
        end

        if v.alertPercentage >= 1 then
            local angleToPlayer = v._StoredRaycastResult.angleToPlayer
            local distToPlayer = v._StoredRaycastResult.distToPlayer

            if v.t % 4 == 0 then
                v:shoot(angleToPlayer)
            end
        end
    
    end
end

function drawEnemies()
    for i,v in ipairs(game.enemies) do
        local x,y = toScreen(v.x,v.y)
        withColor(1,0,0,1,function ()
            love.graphics.circle("fill",x,y,game.cam.scale*v.size/2)

            if v._StoredRaycastResult and v._StoredRaycastResult.playerVisible then
                local endX,endY = toScreen(game.player.x,game.player.y)
                love.graphics.line(x,y,endX,endY)
            end
        end)

        love.graphics.print(v.alertPercentage,x,y)
    end
end


function toGame(x,y)
    return game.cam:toGame(x,y)
end

function toScreen(x,y)
    return game.cam:toScreen(x,y)
end

function drawCrosshair()
    local mx,my = love.mouse.getPosition()
    local opening = (game.player:getSpread()*3)^3 * 15 + 3
    if game.player:getSpread() < 0.1 then opening = 1 end

    local length = 5


    withColor(1,1,1,1,function ()
        love.graphics.line(mx-opening-length,my,mx-opening,my)
        love.graphics.line(mx+opening,my,mx+opening+length,my)
        love.graphics.line(mx,my-opening-length,mx,my-opening)
        love.graphics.line(mx,my+opening,mx,my+opening+length)
    end)
end


function drawMap()
    game.map:drawTileLayer(1,game.tileArr,game.cam)
    game.map:drawTileLayer(2,game.tileArr,game.cam)
end

function thisState.load()
    cursorDotCanv = love.graphics.newCanvas(2,2)
    cursorDotCanv:renderTo(function ()
        withColor(1,1,1,1,function ()
            love.graphics.rectangle("fill",0,0,2,2)
        end)
    end)
    love.mouse.setCursor(love.mouse.newCursor(cursorDotCanv:newImageData(), 1, 1))


    game.cam = camLib.newCam({
        isCenter = true,
        smooth = true,
    })
    game.timer = 120
    game.keysPressedThisFrame = {}
    game.map, game.tileArr = getMapAndTileArr("mapa01")
    game.enemies = {}
    game.projectiles = {}
    game.player = getPlayer(game)
    game.enemies = getEnemies()
    game.gui = getGui(game)


    thisState.resize(love.graphics.getDimensions())
end 

function thisState.update()
    local gmx,gmy = toGame(love.mouse.getPosition())
    

    local mouseWeight = 0.5
    if game.player.isAiming then mouseWeight = 1.2 end
    game.cam:setTargets({
        {x=game.player.x, y=game.player.y, weight=1},
        {x=gmx, y=gmy, weight=mouseWeight},
    })
    game.cam:tick()
    runProjectiles()
    game.player:tick()
    runEnemies()

    game.keysPressedThisFrame = {}
    game.timer = game.timer - 1/TICKS_PER_SECOND
end

function thisState.draw()
    drawMap()
    game.player:draw()
    drawProjectiles()
    drawCrosshair()
    drawEnemies()
    game.gui:draw()

    
end 

function thisState.mousepressed(mx,my,mBtn)
    if mBtn == 3 then
        game.player.x,game.player.y = toGame(mx,my)
    end
    game.keysPressedThisFrame["mouse"..mBtn] = true
end

function thisState.keypressed(key)
    if key == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen())
    end 

    game.keysPressedThisFrame[key] = true
end

function thisState.resize(w,h)
    local min = math.min(w,h)
    local max = math.max(w,h)

    game.cam.scale = (min / 15) + ((max - min) / 15)*0.5

    
end
return thisState
