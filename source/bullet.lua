
local gfx <const> = playdate.graphics
class("Bullet").extends(playdate.graphics.sprite)

local bulletSize = 24
local collisionSize = 3
local NW,N,NE,W,E,SW,S,SE = 1,2,3,4,6,7,8,9
local minXPosition = 10
local maxXPosition = 390
local minYPosition = -230
local maxYPosition = 230

function Bullet:init()
  Bullet.super.init(self)

  self:setSize(bulletSize, bulletSize)
  self:setCollideRect(bulletSize/2-collisionSize/2, bulletSize/2-collisionSize/2, collisionSize, collisionSize)
  self:setGroups({1})
  self:setCollidesWithGroups({1,3})
  self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  function self:setVelocity(dx, dy, facing)
    if dx==0 then self.dx=0 elseif dx<0 then self.dx=-bulletSize*2 else self.dx=bulletSize*2 end
    if dy==0 then self.dy=0 elseif dy<0 then self.dy=-bulletSize*2 else self.dy=bulletSize*2 end
    -- print(dx, dy, da, self.dx, self.dy)
    self.facing = facing
  end

  function self:update()
    local x,y,c,l = self:moveWithCollisions(self.x + self.dx/2, self.y + self.dy/2)

    for i=1,l do
      local other = c[i].other
      if other:isa(Enemy) then
        other:die()
        self:remove()
        player:addScore(10)
      end
      if other:isa(Block) then
        other:hit()
        self:remove()
      end
      if other:isa(Supply) or other.isBalloon then
        other:die()
        self:remove()
      end
    end

    if self.x < minXPosition or self.x > maxXPosition or self.y < minYPosition or self.y > maxYPosition or self.removeme then
      self:remove()
    end
  end

  function self:draw()
    gfx.setLineWidth(2)
    if self.facing == E or self.facing == W then
      gfx.drawLine(0, bulletSize/2, bulletSize, bulletSize/2)
    elseif self.facing == N or self.facing == S then
      gfx.drawLine(bulletSize/2, 0, bulletSize/2, bulletSize)
    elseif self.facing == NE or self.facing == SW then
      gfx.drawLine(0, bulletSize, bulletSize, 0)
    elseif self.facing == SE or self.facing == NW then
      gfx.drawLine(0, 0, bulletSize, bulletSize)
    end
    -- gfx.drawLine(bulletSize, bulletSize, self.dx*bulletSize, self.dy*bulletSize)
  end

  return self
end
