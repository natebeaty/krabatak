
local gfx <const> = playdate.graphics
class("Bullet").extends(playdate.graphics.sprite)

local collisionSize = 3
local NW,N,NE,W,E,SW,S,SE = 1,2,3,4,6,7,8,9
local minXPosition = 10
local maxXPosition = 390
local minYPosition = -230
local maxYPosition = 230

function Bullet:init(bulletSize)
  Bullet.super.init(self)
  self.bulletSize = bulletSize
  self:setSize(self.bulletSize, self.bulletSize)
  self:setCollideRect(self.bulletSize/2-collisionSize/2, self.bulletSize/2-collisionSize/2, collisionSize, collisionSize)
  self:setGroups({1})
  self:setCollidesWithGroups({1,3})
  -- self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  function self:setVelocity(dx, dy, facing)
    if dx==0 then self.dx=0 elseif dx<0 then self.dx=-self.bulletSize*2 else self.dx=self.bulletSize*2 end
    if dy==0 then self.dy=0 elseif dy<0 then self.dy=-self.bulletSize*2 else self.dy=self.bulletSize*2 end
    -- print(dx, dy, da, self.dx, self.dy)
    self.facing = facing
  end

  function self:update()
    local x,y,c,l = self:moveWithCollisions(self.x + self.dx/2, self.y + self.dy/2)

    for i=1,l do
      local other = c[i].other
      if other.isEnemy then
        other:die()
        self:remove()
        player:addScore(other.points)
        checkLevel()
      elseif other:isa(Block) then
        other:hit()
        self:remove()
      elseif other:isa(Supply) or other.isBalloon then
        other:die()
        self:remove()
      else
        self:remove()
      end
    end

    if self.x < minXPosition or self.x > maxXPosition or self.y < minYPosition or self.y > maxYPosition or self.removeme then
      self:remove()
    end
  end

  function self:draw()
    if self.facing == E or self.facing == W then
      x1, y1, x2, y2 = 0, self.bulletSize/2, self.bulletSize, self.bulletSize/2
    elseif self.facing == N or self.facing == S then
      x1, y1, x2, y2 = self.bulletSize/2, 0, self.bulletSize/2, self.bulletSize
    elseif self.facing == NE or self.facing == SW then
      x1, y1, x2, y2 = 0, self.bulletSize, self.bulletSize, 0
    elseif self.facing == SE or self.facing == NW then
      x1, y1, x2, y2 = 0, 0, self.bulletSize, self.bulletSize
    end
    -- x1, y1, x2, y2 = self.bulletSize, self.bulletSize, self.dx*self.bulletSize, self.dy*self.bulletSize

    gfx.setColor(gfx.kColorWhite)
    gfx.setLineWidth(2)
    gfx.drawLine(x1, y1-1, x2, y2-1)
    gfx.drawLine(x1, y1+1, x2, y2+1)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(x1, y1, x2, y2)
  end

  return self
end
