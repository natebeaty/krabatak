local gfx <const> = playdate.graphics
local sound <const> = playdate.sound
local vector2D <const> = playdate.geometry.vector2D
local frameTimer <const> = playdate.frameTimer
local random <const>, sin <const>, cos <const>, atan2 <const> = math.random, math.sin, math.cos, math.atan2

class("Bishop").extends(gfx.sprite)

local bishopImagesTable = gfx.imagetable.new("images/bishop")
local bishopDamagedImagesTable = gfx.imagetable.new("images/bishop-damaged")
local bishopDeathSfx = sound.sampleplayer.new("sounds/bishop-death")
local bishopHitSfx = sound.sampleplayer.new("sounds/bishop-hit")
local bishopCache = {}

-- Bishops
function removeBishop(bishop)
  if bishop.laser then
    removeLaser(bishop.laser)
  end
  bishop.directionTimer:pause()
  bishop.stepTimer:pause()
  bishop.hits = 1
  bishop:remove()
  bishopCache[#bishopCache+1] = bishop
end

function addBishop(initialPosition)
  local bishop = nil
  if #bishopCache > 0 then
    bishop = table.remove(bishopCache)
    bishop.directionTimer:start()
    bishop.stepTimer:start()
  else
    bishop = Bishop()
  end
  bishop.position = initialPosition or point.new(rnd(400), 0)
  bishop.velocity = vector2D.new((rnd(3)-2)*1.25, rnd(2)*1.5)
  bishop:moveTo(bishop.position)
  return bishop
end

function Bishop:init()
  Bishop.super.init(self)
  self:setImage(bishopImagesTable:getImage(1))
  self:setZIndex(900)
  self:setCollideRect(2, 2, 33, 24)
  self:setGroups({1})
  self:setCollidesWithGroups({1})
  self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  self.stepTimer = frameTimer.new(6)
  self.stepTimer.repeats = true
  self.directionTimer = frameTimer.new(random(50)+100, function()
    self:changeDirection()
  end)
  self.directionTimer.repeats = true

  self.isEnemy = true
  self.points = 20
  self.hits = 1
  self.lasering = 0
  return self
end

function Bishop:isDamaged()
  return self.hits < 1
end

function Bishop:changeDirection()
  self.directionTimer.duration = self:isDamaged() and random(50)+50 or random(100)+200
  self.directionTimer:reset()
  local multiplier = self:isDamaged() and 5 or 0.55
  local dx, dy = (rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1.25) * multiplier, (rnd()) * (enemySpeed * enemySpeed * 49/10000+1.25) * multiplier
  if self.position.y > (verticalScroll and -230 or -20) then
    dy=(rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1.25) * multiplier
  end
  self.velocity = vector2D.new(dx, dy)
end

function Bishop:die()
  Animations:explosion(self.position.x, self.position.y)
  if self.hits == 0 then
    bishopDeathSfx:play()
    del(bishops, self)
    removeBishop(self)
    return true
  else
    bishopHitSfx:play()
    -- abruptly move towards player when hit
    local angleToPlayer = atan2(player.y - self.y, player.x - self.x)
    local dx, dy = cos(angleToPlayer) * 1.5, sin(angleToPlayer) * 1.5
    self.velocity = vector2D.new(dx, dy)
    self.directionTimer.duration = random(250)+50
    self.hits -= 1
    return false
  end
  -- self.directionTimer:remove()
  -- self:remove()
end

function Bishop:update()
  -- show damage if hit
  if self:isDamaged() then
    self:setImage(bishopDamagedImagesTable:getImage(self.stepTimer.frame % 6 + 1))
  else
    self:setImage(bishopImagesTable:getImage(self.stepTimer.frame % 6 + 1))
  end

  -- start lasering?
  if self.lasering == 0  and isVisible(self.x,self.y,self.width,self.height) and random(1000)>995 then
    self.lasering = 150
    self.laser = addLaser(self.x, self.y)
  end

  -- if not lasering, move
  if self.lasering == 0 then
    self.position += self.velocity
    self:moveTo(self.position)
  else
    if self:isDamaged() then
      -- move slowly while lasering if damaged
      self.position += self.velocity * 0.15
      self:moveTo(self.position)
      self.laser:setPosition(self.x, self.y)
    end
    self.lasering -= 1
  end

  -- offscreen?
  if self.position.y > enemyMaxY or self.position.y < (verticalScroll and -230 or 0) then
    self.velocity.y = -self.velocity.y;
  end
  if self.position.x < enemyMinX or self.position.x > enemyMaxX then
    -- self.position = point.new(rnd(400), -cameraY)
    self.velocity.x = -self.velocity.x;
  end
end
