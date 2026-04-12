local LIB = {}

local function collapseTargets(_Targets)
    local sumX = 0
    local sumY = 0
    local sumW = 0

    for i,v in ipairs(_Targets) do
        local weight = v.weight or 1
        sumX = sumX + v.x*weight
        sumY = sumY + v.y*weight
        sumW = sumW + weight
    end

    return sumX/sumW, sumY/sumW
end

local function internalTickFunction(self)
    local wantX,wantY = self.wantX, self.wantY
    
    if self.isCenter then
        local screenW,screenH = love.window.getMode()
        wantX = wantX - (screenW/self.scale)/2
        wantY = wantY - (screenH/self.scale)/2
    end

    if self.smooth then
        self.offX = (self.offX + wantX*0.1) / 1.1
        self.offY = (self.offY + wantY*0.1) / 1.1
    else
        self.offX = wantX
        self.offY = wantY
    end
end

local function setTargetFunction(self,_X,_Y)
    self.wantX = _X
    self.wantY = _Y
end

local function setTargetsFunction(self,_Targets)
    local x,y = collapseTargets(_Targets)
    self.wantX = x
    self.wantY = y
end

local function setOffFunction(self,_X,_Y)
    self.offX = _X
    self.offY = _Y
    self.wantX = _X
    self.wantY = _Y
end

local function toGameFunction(self,x,y)
    local newX = (x/self.scale)+self.offX
    local newY = (y/self.scale)+self.offY
    return newX,newY
end

local function toScreenFunction(self,x,y)
    local newX = (x-self.offX)*self.scale
    local newY = (y-self.offY)*self.scale
    return newX,newY
end

--- Creates a new camera object
function LIB.newCam(_Options)
    _Options = _Options or {}
    local newCam = {
        offX = _Options.offX or 0,
        offY = _Options.offY or 0,
        scale = _Options.scale or 50,
        smooth = _Options.smooth or false,
        isCenter = _Options.isCenter ~= false,
        
        wantX = _Options.offX or 0,
        wantY = _Options.offY or 0,
        
        tick = internalTickFunction,
        setTarget = setTargetFunction,
        setTargets = setTargetsFunction,
        setOff = setOffFunction,
        toGame = toGameFunction,
        toScreen = toScreenFunction,
    }
    return newCam
end

return LIB