import "CoreLibs/animation"
import "lib/state"

local gfx <const> = playdate.graphics
class("Player").extends(gfx.sprite)

local frameTimer <const> = playdate.frameTimer
local point <const> = playdate.geometry.point
local vector2D <const> = playdate.geometry.vector2D
local min, max, abs, floor = math.min, math.max, math.abs, math.floor

-- local maxVelocity = 5.4
-- local minVelocity = 1.8
-- local flyVelocity = 2.1
-- local flyFriction = 0.95

local maxVelocity = 9
local minVelocity = 2
local flyAcceleration = 1.5
local flyAccelerationNeutral = 0.75
local flyFriction = 0.85
local NW,N,NE,W,E,SW,S,SE = 1,2,3,4,6,7,8,9 -- plane sprite indexes
local startX = 15
local startY = 182
local minXPosition = 10
local maxXPosition = 390
local minYPosition = -230
local maxYPosition = 230
local playerImages = gfx.imagetable.new("images/player")

function Player:init()
  Player.super.init(self)
  self.facing = N
  self:setImage(playerImages:getImage(self.facing))
  self:setZIndex(1000)
  self:moveTo(startX, startY)
  self:setCollideRect(5,5,30,30)
  self:setGroups({1})
  self:setCollidesWithGroups({1})
  self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  self.life = 3
  self.score = 10
  self.fuel = 999
  self.position = point.new(startX, startY)
  self.mode = "plane"
  self.exploding = false
  self.velocity = vector2D.new(0,0)
end

function Player:die()
  print("die", self.dying)
  new_explosion(self.position.x, self.position.y)
  self.life -= 1
  self.dying = 1
  self.position = point.new(startX, startY)
  self.velocity = vector2D.new(0,0)
  self.resetPlayerTimer = frameTimer.new(20, player_respawn)
  print("died", self.dying)
end

function Player:respawn()
  print("respawn", self.dying)
  setCameraY()
  self.facing = N
  self.fuel = 999
  self:setImage(playerImages:getImage(self.facing))
  self.position = point.new(startX, startY)
  self.velocity = vector2D.new(0,0)
  self.dying = nil
end


function Player:update()
  if self.dying ~= nil then
    self:setImage(nil)
    self:moveTo(self.position)
    return
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
    self.velocity.y = self.velocity.y - flyAcceleration
  elseif downPressed then
    if leftPressed then
      self.facing = SW
    elseif rightPressed then
      self.facing = SE
    else
      self.facing = S
      self.velocity.x = 0
    end
    self.velocity.y = self.velocity.y + flyAcceleration
  end

  if leftPressed then
    if not upPressed and not downPressed then
      self.velocity.y = 0
      self.facing = W
    end
    self.velocity.x = self.velocity.x - flyAcceleration
  elseif rightPressed then
    if not upPressed and not downPressed then
      self.facing = E
      self.velocity.y = 0
    end
    self.velocity.x = self.velocity.x + flyAcceleration
  end

  if self.facing == E or self.facing == W then
    self:setCollideRect(8,15,25,10)
  else
    self:setCollideRect(10,10,20,20)
  end

  self.velocity.x = self.velocity.x * flyFriction
  self.velocity.y = self.velocity.y * flyFriction

  -- if no button pressed,
  if nobuttonPressed then
    if abs(self.velocity.x) < minVelocity or abs(self.velocity.y) < minVelocity then
      -- print(self.velocity.x, self.velocity.y, self.facing==N)
      if self.facing==N then self.velocity += vector2D.new(0,-flyAccelerationNeutral) end
      if self.facing==S then self.velocity += vector2D.new(0,flyAccelerationNeutral) end
      if self.facing==E then self.velocity += vector2D.new(flyAccelerationNeutral,0) end
      if self.facing==W then self.velocity += vector2D.new(-flyAccelerationNeutral,0) end
      if self.facing==NE then self.velocity += vector2D.new(flyAccelerationNeutral,-flyAccelerationNeutral) end
      if self.facing==NW then self.velocity += vector2D.new(-flyAccelerationNeutral,-flyAccelerationNeutral) end
      if self.facing==SE then self.velocity += vector2D.new(flyAccelerationNeutral,flyAccelerationNeutral) end
      if self.facing==SW then self.velocity += vector2D.new(-flyAccelerationNeutral,flyAccelerationNeutral) end
    else
      self.velocity.x = capVelocity(self.velocity.x, minVelocity)
      self.velocity.y = capVelocity(self.velocity.y, minVelocity)
    end
  else
    -- clamp velocity to min/max if moving
    self.velocity.x = capVelocity(self.velocity.x, maxVelocity)
    self.velocity.y = capVelocity(self.velocity.y, maxVelocity)

    -- self.velocity.x = minMaxVelocity(self.velocity.x, minVelocity, maxVelocity)
    -- self.velocity.y = minMaxVelocity(self.velocity.y, minVelocity, maxVelocity)
  end

  -- self.velocity.x = capVelocity(self.velocity.x,maxVelocity)
  -- self.velocity.y = capVelocity(self.velocity.y,maxVelocity)

  -- fuel check
  if self.mode=="man" then
    -- manfuel
    self.fuel-=0.1
  else
    --planefuel (empties faster based on velocity)
    if (self.velocity.y~=0 or self.velocity.x~=0) then self.fuel-=(abs(self.velocity.x)+abs(self.velocity.y))*0.1 else self.fuel-=0.1 end
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
  if self.position.x < minXPosition then
    self.velocity.x = 0
    self.position.x = minXPosition
  elseif self.position.x > maxXPosition then
    self.velocity.x = 0
    self.position.x = maxXPosition
  end
  if self.position.y < minYPosition then
    self.velocity.y = 0
    self.position.y = minYPosition
  elseif self.position.y > maxYPosition then
    self.velocity.y = 0
    self.position.y = maxYPosition
  end

  -- set player sprite based on direction
  self:setImage(playerImages:getImage(self.facing))

  local x,y,c,l = self:moveWithCollisions(self.position)
  for i = 1, l do
    if self.dying then return end
    local collision = c[i]
    if collision.other:isa(Enemy) == true then
      self:die()
      collision.other:die()
    end
    if collision.other:isa(Block) == true then
      self:die()
      collision.other:hit()
    end
  end

end

-- shoot!
function Player:shoot()
  if mode=="game" and (self.mode=="man" or abs(self.velocity.x)~=0 or abs(self.velocity.y)~=0) then

    -- sfx(00)
    local bulletVelocity = nil

    if self.facing==N then bulletVelocity = vector2D.new(0,-flyAccelerationNeutral) end
    if self.facing==S then bulletVelocity = vector2D.new(0,flyAccelerationNeutral) end
    if self.facing==E then bulletVelocity = vector2D.new(flyAccelerationNeutral,0) end
    if self.facing==W then bulletVelocity = vector2D.new(-flyAccelerationNeutral,0) end
    if self.facing==NE then bulletVelocity = vector2D.new(flyAccelerationNeutral,-flyAccelerationNeutral) end
    if self.facing==NW then bulletVelocity = vector2D.new(-flyAccelerationNeutral,-flyAccelerationNeutral) end
    if self.facing==SE then bulletVelocity = vector2D.new(flyAccelerationNeutral,flyAccelerationNeutral) end
    if self.facing==SW then bulletVelocity = vector2D.new(-flyAccelerationNeutral,flyAccelerationNeutral) end

    -- support for quick turn and shoots when direction doesn't match flipx/flipy
    -- if self.velocity.y==0 and ((self.facing == W and self.velocity.x > 0) or (self.facing == E and self.velocity.x < 0)) then vx=self.velocity.x*-1 end
    -- if self.velocity.x==0 and ((self.facing == N and self.velocity.y<0) or (self.facing == S and self.velocity.y>0)) then vy=self.velocity.y*-1 end

    local b = Bullet()
    b:moveTo(self.position.x+bulletVelocity.x*20, self.position.y+bulletVelocity.y*20)
    b:setVelocity(bulletVelocity.x, bulletVelocity.y, self.facing)
    b:addSprite()

  end
end
