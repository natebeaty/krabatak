import "CoreLibs/animation"

class('Player').extends(playdate.graphics.sprite)

-- local references
local gfx <const> = playdate.graphics
local point <const> = playdate.geometry.point
local rect <const> = playdate.geometry.rect
local vector2D <const> = playdate.geometry.vector2D
local affineTransform <const> = playdate.geometry.affineTransform
local min, max, abs, floor = math.min, math.max, math.abs, math.floor

-- constants
local MAX_VELOCITY = 5.4
local MIN_VELOCITY = 1.8
local FLY_VELOCITY = 2.1
local FLY_FRICTION = 0.95
-- plane sprite indexes
local NW,N,NE,W,E,SW,S,SE = 1,2,3,4,6,7,8,9
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

  self.life = 3
  self.score = 10
  self.fuel = 999
  self.position = point.new(startX, startY)
  self.mode = "plane"
  self.exploding = false
  self.velocity = vector2D.new(0,0)
end

function Player:die()
  new_explosion(self.position.x, self.position.y)
  self.life -= 1
  self.dying = 1
  self.resetPlayerTimer = playdate.frameTimer.new(10, player_respawn)
end

function Player:respawn()
  self.facing = N
  self:setImage(playerImages:getImage(self.facing))
  self.position = point.new(startX, startY)
  self.velocity = vector2D.new(0,0)
  self.dying = nil
end


function Player:update()
  if self.dying ~= nil then
    self:setImage(nil)
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
    self.velocity.y = self.velocity.y - FLY_VELOCITY
  elseif downPressed then
    if leftPressed then
      self.facing = SW
    elseif rightPressed then
      self.facing = SE
    else
      self.facing = S
      self.velocity.x = 0
    end
    self.velocity.y = self.velocity.y + FLY_VELOCITY
  end

  if leftPressed then
    if not upPressed and not downPressed then
      self.velocity.y = 0
      self.facing = W
    end
    self.velocity.x = self.velocity.x - FLY_VELOCITY
  elseif rightPressed then
    if not upPressed and not downPressed then
      self.facing = E
      self.velocity.y = 0
    end
    self.velocity.x = self.velocity.x + FLY_VELOCITY
  end

  if self.facing == E or self.facing == W then
    self:setCollideRect(8,15,25,10)
  else
    self:setCollideRect(10,10,20,20)
  end

  self.velocity.x = self.velocity.x * FLY_FRICTION
  self.velocity.y = self.velocity.y * FLY_FRICTION

  -- if playdate.buttonIsPressed("B") then
  if playdate.buttonJustPressed("A") then
    self:shoot()
  end

  -- don't accelerate past max velocity
  self.velocity.x = maxVelocity(self.velocity.x, MAX_VELOCITY)
  self.velocity.y = maxVelocity(self.velocity.y, MAX_VELOCITY)
  self.velocity.x = minVelocity(self.velocity.x, MIN_VELOCITY)
  self.velocity.y = minVelocity(self.velocity.y, MIN_VELOCITY)

  if (nobuttonPressed) then
    if self.velocity.x==0 and self.velocity.y<0 then self.facing=N end
    if self.velocity.x==0 and self.velocity.y>0 then self.facing=S end
    if self.velocity.x>0 and self.velocity.y==0 then self.facing=E end
    if self.velocity.x<0 and self.velocity.y==0 then self.facing=W end
    if self.velocity.x>0 and self.velocity.y<0 then self.facing=NE end
    if self.velocity.x<0 and self.velocity.y<0 then self.facing=NW end
    if self.velocity.x>0 and self.velocity.y>0 then self.facing=SE end
    if self.velocity.x<0 and self.velocity.y>0 then self.facing=SW end
  end


  -- update Player position based on current velocity
  local velocityStep = self.velocity
  self.position = self.position + velocityStep

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

  local collisions, len
  self.position.x, self.position.y, collisions, len = self:moveWithCollisions(self.position)
  for i = 1, len do
    local collision = collisions[i]
    if collision.other:isa(Enemy) == true then -- crashed into enemy
      collision.other:die()
      self:die()
    end
  end

end

-- shoot!
function Player:shoot()
  if mode=="game" and (self.mode=="man" or abs(self.velocity.x)~=0 or abs(self.velocity.y)~=0) then

    -- sfx(00)
    local vx=self.velocity.x
    local vy=self.velocity.y

    -- support for quick turn and shoots when direction doesn't match flipx/flipy
    -- if self.velocity.y==0 and ((self.facing == W and self.velocity.x > 0) or (self.facing == E and self.velocity.x < 0)) then vx=self.velocity.x*-1 end
    -- if self.velocity.x==0 and ((self.facing == N and self.velocity.y<0) or (self.facing == S and self.velocity.y>0)) then vy=self.velocity.y*-1 end

    local b = Bullet:new()
    b:moveTo(self.position.x-1, self.position.y-1)
    b:setVelocity(self.velocity.x, self.velocity.y, self.facing)
    b:addSprite()

  end
end

function Player:collisionResponse(other)
  -- if other:isa(Enemy) then
    return "overlap"
  -- end
  -- return "bounce"
end
