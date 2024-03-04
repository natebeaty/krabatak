local gfx <const> = playdate.graphics
local sound <const> = playdate.sound

class("Bullet").extends(playdate.graphics.sprite)

local collisionSize = 3
local minXPosition = -40
local maxXPosition = 440
local minYPosition = -250
local maxYPosition = 250

local bulletSfx = sound.sampleplayer.new("sounds/bullet")
local bulletCache = {}

function addBullet(bulletSize, x, y, dx, dy, facing)
  local bullet = nil
  if #bulletCache > 0 then
    bullet = table.remove(bulletCache)
    bullet:setBulletSize(bulletSize)
  else
    bullet = Bullet(bulletSize)
  end

  bullet:moveTo(x, y)
  bullet:setVelocity(dx, dy, facing)
  bullet:add()

  bulletSfx:play()
end

function removeBullet(bullet)
  bullet:remove()
  bulletCache[#bulletCache+1] = bullet
end

function Bullet:init(bulletSize)
  Bullet.super.init(self)

  self:setBulletSize(bulletSize)
  self:setGroups({1})
  self:setCollidesWithGroups({1,3})
  -- self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  return self
end

-- update bullet size + collideRect (bullet can be vertical, horizontal, diagonal)
function Bullet:setBulletSize(bulletSize)
  self.bulletSize = bulletSize
  self:setSize(self.bulletSize, self.bulletSize)
  self:setCollideRect(self.bulletSize/2-collisionSize/2, self.bulletSize/2-collisionSize/2, collisionSize, collisionSize)
end

-- set bullet velocity after init
function Bullet:setVelocity(dx, dy, facing)
  if dx==0 then self.dx=0 elseif dx<0 then self.dx=-self.bulletSize*2 else self.dx=self.bulletSize*2 end
  if dy==0 then self.dy=0 elseif dy<0 then self.dy=-self.bulletSize*2 else self.dy=self.bulletSize*2 end
  -- print(dx, dy, da, self.dx, self.dy)
  self.facing = facing
end

function Bullet:update()
  local x,y,c,l = self:moveWithCollisions(self.x + self.dx/2, self.y + self.dy/2)

  for i=1,l do
    local other = c[i].other
    if other.isEnemy then
      other:die()
      player:addScore(other.points)
      checkLevel()
    elseif other.isBossTarget then
      other.parent:hit(self.x,self.y)
    elseif other:isa(Block) and not other.broken then
      other:hit()
    elseif other:isa(Supply) or other.isBalloon then
      other:die()
    end
    if not other.isBoss then
      removeBullet(self)
    end
  end

  if self.x < minXPosition or self.x > maxXPosition or self.y < minYPosition or self.y > maxYPosition or self.removeme then
    removeBullet(self)
  end
end

function Bullet:draw()
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

function Bullet:collisionResponse(other)
  if other.isBoss then
    return "overlap"
  else
    return "freeze"
  end
end
