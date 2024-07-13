import "CoreLibs/animation"

local gfx <const> = playdate.graphics
local sound <const> = playdate.sound
class("Player").extends(gfx.sprite)

local frameTimer <const> = playdate.frameTimer
local point <const> = playdate.geometry.point
local vector2D <const> = playdate.geometry.vector2D
local min, max, abs, floor = math.min, math.max, math.abs, math.floor
local screenWidth <const>, _ = playdate.display.getSize()

local planeMinVelocity = 3
local planeMaxVelocity = 9
local manMinVelocity = 0
local manMaxVelocity = 3
local planeAcceleration = 1.5
local planeAccelerationNeutral = 0.75
local planeFriction = 0.85
local manFriction = 0.55
local planeStartY = 186
local manStartY = 214
local leftStartX = 15 -- left dock X
local rightStartX = 384 -- right dock X
local playerMinX = 10
local planeDocked = "left"
playerMinY = 33
if verticalScroll then
  playerMinY = -220
end
local playerMaxX = 390
local playMaxY = 230
local planeImages = gfx.imagetable.new("images/plane")
local manImages = gfx.imagetable.new("images/man")
local platformManImages = gfx.imagetable.new("images/platform-man")

-- sounds
local crashSfx = sound.sampleplayer.new("sounds/crash")
local manDeathSfx = sound.sampleplayer.new("sounds/man-death")
local manPlaneSwitchSfx = sound.sampleplayer.new("sounds/man-plane-switch")
local extralifeSfx = sound.sampleplayer.new("sounds/extra-life")

-- player init
function Player:init()
  Player.super.init(self)
  self.facing = N
  self:setImage(planeImages:getImage(self.facing))
  self:setZIndex(1000)
  self:setGroups({1})
  self:setCollidesWithGroups({1,3})
  self:setCollideRect(13,11,6,10)
  -- set initial attributes
  self:restart()
  -- add self to stage
  self:add()
end

-- draw static docked plane when mode=="man"
function drawPlane()
  -- draw static plane
  planeImages:drawImage(N, planeDocked=="left" and leftStartX-20 or rightStartX-20, 167)
end

-- player has died
function Player:die(x,y)
  x = x or self.position.x
  y = y or self.position.y
  if self.mode == "man" then
    manDeathSfx:play()
  else
    crashSfx:play()
  end
  animations:explosion(x, y)

  -- lower lives and trigger updating status bar
  self.life -= 1

  statusBar:markDirty()
  self.dying = 1
  -- self.mode = "man"
  self.position = point.new(leftStartX, manStartY)
  self.velocity = vector2D.new(0,0)
  self:setCollideRect(13,11,6,10)
  self.resetPlayerTimer = frameTimer.new(20, function()
    resetCamera()
    player:respawn()
  end)
  if self.life == 0 then
    gameOver()
  end
end

-- respawn player after dying
function Player:respawn()
  self.facing = N
  self.fuel = 999
  -- move player to starting point
  planeDocked = "left"
  self:setImage(planeImages:getImage(self.facing))
  self.position = point.new(leftStartX, manStartY)
  self:moveTo(self.position)
  self.velocity = vector2D.new(0,0)
  self.dying = nil
end

-- restart player attributes for new game
function Player:restart()
  self.mode = "man"
  self:setCollideRect(13,11,6,10)
  self.extralife = 0
  self.life = 3
  self.score = 0
  self:respawn()
end

-- player update loop
function Player:update()
  -- dying?
  if (mode ~= "game" and mode ~= "boss1") or self.dying ~= nil then
    self:setImage(nil)
    self:moveTo(self.position)
    return
  end

  local minVelocity = planeMinVelocity
  local maxVelocity = planeMaxVelocity
  local friction = planeFriction

  --man slow, plane fast
  if self.mode=="man" then
    minVelocity = manMinVelocity
    maxVelocity = manMaxVelocity
    friction = manFriction
  end

  local upPressed, downPressed, leftPressed, rightPressed = playdate.buttonIsPressed("UP"), playdate.buttonIsPressed("DOWN"), playdate.buttonIsPressed("LEFT"), playdate.buttonIsPressed("RIGHT")
  local nobuttonPressed = not upPressed and not downPressed and not leftPressed and not rightPressed
  if upPressed then
    if leftPressed then
      self.facing = NW
    elseif rightPressed then
      self.facing = NE
    else
      self.facing = N
      self.velocity.x = 0
    end
    self.velocity.y = self.velocity.y - planeAcceleration
  elseif downPressed then
    if leftPressed then
      self.facing = SW
    elseif rightPressed then
      self.facing = SE
    else
      self.facing = S
      self.velocity.x = 0
    end
    self.velocity.y = self.velocity.y + planeAcceleration
  end

  if leftPressed then
    if not upPressed and not downPressed then
      self.velocity.y = 0
      self.facing = W
    end
    self.velocity.x = self.velocity.x - planeAcceleration
  elseif rightPressed then
    if not upPressed and not downPressed then
      self.facing = E
      self.velocity.y = 0
    end
    self.velocity.x = self.velocity.x + planeAcceleration
  end

  -- set collision based on mode
  if self.mode == "plane" then
    if self.facing == E or self.facing == W then
      self:setCollideRect(8,15,25,10)
    else
      self:setCollideRect(10,10,20,20)
    end
  end

  -- if no button pressed
  if nobuttonPressed then
    if self.mode=="plane" then
      if (self.velocity.x~=0 and abs(self.velocity.x) < minVelocity) or (self.velocity.y~=0 and abs(self.velocity.y) < minVelocity) then
        if self.facing==N then self.velocity += vector2D.new(0,-planeAccelerationNeutral) end
        if self.facing==S then self.velocity += vector2D.new(0,planeAccelerationNeutral) end
        if self.facing==E then self.velocity += vector2D.new(planeAccelerationNeutral,0) end
        if self.facing==W then self.velocity += vector2D.new(-planeAccelerationNeutral,0) end
        if self.facing==NE then self.velocity += vector2D.new(planeAccelerationNeutral,-planeAccelerationNeutral) end
        if self.facing==NW then self.velocity += vector2D.new(-planeAccelerationNeutral,-planeAccelerationNeutral) end
        if self.facing==SE then self.velocity += vector2D.new(planeAccelerationNeutral,planeAccelerationNeutral) end
        if self.facing==SW then self.velocity += vector2D.new(-planeAccelerationNeutral,planeAccelerationNeutral) end
      else
        self.velocity.x = caplowVelocity(self.velocity.x, minVelocity)
        self.velocity.y = caplowVelocity(self.velocity.y, minVelocity)
      end
    end
  else
    -- clamp velocity to min/max if moving
    self.velocity.x = capVelocity(self.velocity.x, maxVelocity)
    self.velocity.y = capVelocity(self.velocity.y, maxVelocity)
    -- print(self.velocity.x, maxVelocity)
  end

  self.velocity.x = self.velocity.x * friction
  self.velocity.y = self.velocity.y * friction

  -- fuel check
  if self.mode=="man" then
    self.fuel -= 0.1
  else
    -- plane fuel empties faster based on velocity
    if (self.velocity.y~=0 or self.velocity.x~=0) then self.fuel -= (abs(self.velocity.x)+abs(self.velocity.y))*0.1 else self.fuel -= 0.1 end
  end

  --low fuel klaxon
  -- if (self.fuel < self.lowfuel and t%40==0) sfx(13)
  self.fuel = math.max(self.fuel,0)
  --out of fuel!
  if (self.fuel==0) then self:die() end

  -- if playdate.buttonIsPressed("B") then
  if playdate.buttonJustPressed("A") then
    self:shoot()
  end

  -- update Player position based on current velocity
  self.position = self.position + self.velocity

  -- don't move outside the walls of the game
  if self.position.x < playerMinX then
    self.velocity.x = 0
    self.position.x = playerMinX
  elseif self.position.x > playerMaxX then
    self.velocity.x = 0
    self.position.x = playerMaxX
  end
  if self.position.y < playerMinY then
    self.velocity.y = 0
    self.position.y = playerMinY
  elseif self.position.y > playMaxY then
    self.velocity.y = 0
    self.position.y = playMaxY
  end

  -- set player sprite based on direction
  if self.mode=="plane" then
    self:setImage(planeImages:getImage(self.facing))
  else
    self:setImage(manImages:getImage(self.facing))
  end

  local x,y,c,l = self:moveWithCollisions(self.position)
  self.position = point.new(x,y)

  for i = 1, l do
    local other = c[i].other
    if other.boundaryName and other.boundaryName=="playerModeSwitch" then
      self:switchMode()
    elseif other.isBoss then
      self:die()
    elseif other.isEnemy then
      self:die()
      other:die()
    elseif other:isa(Supply) then
      self:die()
      other:die()
    elseif other:isa(Train) then
      self:die()
    elseif other:isa(Block) then
      self:die()
      other:hit()
    elseif other:isa(BossBullet) then
      self:die()
    end
  end

end

function Player:refuel()
  manPlaneSwitchSfx:play()
  self.fuel = min(self.fuel + 400, 999)
end

function Player:addScore(n)
  player.score += n

  -- extra life?
  self.extralife += n
  if self.extralife >= 1000 then
    self.extralife = 0
    if (self.life < 5) then
      extralifeSfx:play()
      self.life += 1
    end
  end

  statusBar:markDirty()
end

function Player:switchMode()
  manPlaneSwitchSfx:play()
  local startX = nil
  if (self.position.x < 50) then
    startX = leftStartX
    planeDocked = "left"
  else
    planeDocked = "right"
    startX = rightStartX
  end
  --switch between man/plane?
  if self.mode=="man" then
    self.mode="plane"
    self.position = point.new(startX, planeStartY)
    self.velocity = vector2D.new(0, -planeMinVelocity)
    self.facing = N
    self:moveTo(self.position)
    self:setImage(planeImages:getImage(self.facing))
    -- sfx(10)
  elseif self.mode=="plane" then
    self.mode="man"
    self.position = point.new(startX, manStartY)
    self.velocity = vector2D.new(0, 0)
    self:setCollideRect(13,11,6,10)
    self:moveTo(self.position)
    self:setImage(manImages:getImage(self.facing))
    -- sfx(10)
  end
end

function Player:collisionResponse(other)
  -- If hitting balloon or player man/plane switch, sprites overlay
  if other.isBalloon or other.isEnemy or (other.boundaryName and other.boundaryName == "playerModeSwitch") then
    return "overlap"
  else
    return "freeze"
  end
end

-- shoot!
function Player:shoot()
  if (mode=="game" or mode=="boss1") and (self.mode=="man" or abs(self.velocity.x)~=0 or abs(self.velocity.y)~=0) then

    local bulletVelocity = nil

    if self.facing==N then bulletVelocity = vector2D.new(0,-planeAccelerationNeutral) end
    if self.facing==S then bulletVelocity = vector2D.new(0,planeAccelerationNeutral) end
    if self.facing==E then bulletVelocity = vector2D.new(planeAccelerationNeutral,0) end
    if self.facing==W then bulletVelocity = vector2D.new(-planeAccelerationNeutral,0) end
    if self.facing==NE then bulletVelocity = vector2D.new(planeAccelerationNeutral,-planeAccelerationNeutral) end
    if self.facing==NW then bulletVelocity = vector2D.new(-planeAccelerationNeutral,-planeAccelerationNeutral) end
    if self.facing==SE then bulletVelocity = vector2D.new(planeAccelerationNeutral,planeAccelerationNeutral) end
    if self.facing==SW then bulletVelocity = vector2D.new(-planeAccelerationNeutral,planeAccelerationNeutral) end

    -- support for quick turn and shoots when direction doesn't match flipx/flipy
    -- if self.velocity.y==0 and ((self.facing == W and self.velocity.x > 0) or (self.facing == E and self.velocity.x < 0)) then vx=self.velocity.x*-1 end
    -- if self.velocity.x==0 and ((self.facing == N and self.velocity.y<0) or (self.facing == S and self.velocity.y>0)) then vy=self.velocity.y*-1 end

    -- add bullet at location and matching velocity of direction
    local bulletSize = self.mode=="man" and 12 or 24
    addBullet(bulletSize, self.position.x + bulletVelocity.x * 20, self.position.y + bulletVelocity.y * 20, bulletVelocity.x, bulletVelocity.y, self.facing)

  end
end
