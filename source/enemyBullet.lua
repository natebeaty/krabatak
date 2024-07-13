local pd <const> = playdate
local gfx <const> = pd.graphics
local sound <const> = pd.sound
local random <const>, sin <const>, cos <const>, atan2 <const> = math.random, math.sin, math.cos, math.atan2

class("EnemyBullet").extends(gfx.sprite)

local bulletGfx = gfx.imagetable.new("images/bullet-blorb")
local bulletCache = {}
local bulletHitSfx = sound.sampleplayer.new("sounds/crash")

function addEnemyBullet(x, y, angle, speed)
  local bullet = nil
  if #bulletCache > 0 then
    bullet = table.remove(bulletCache)
  else
    bullet = EnemyBullet()
  end
  bullet:moveTo(x, y)
  bullet:setVelocity(angle, speed)
  bullet:add()
  -- bullet:sfx()
end

function removeEnemyBullet(bullet)
  bullet:remove()
  bulletCache[#bulletCache+1] = bullet
end

function EnemyBullet:init(type)
  EnemyBullet.super.init(self)

  self:setGroups({1})
  self:setCollidesWithGroups({1,3})
  self:setZIndex(1002)
  self.collisionResponse = gfx.sprite.kCollisionTypeOverlap
  local bullet = bulletGfx:getImage(1)
  self:setImage(bullet)
  self:setCollideRect(0, 0, bullet:getSize())

  self.t = 0
  self.isEnemyBullet = true

  return self
end

-- set bullet velocity after init
function EnemyBullet:setVelocity(angle, speed)
  self.dx = speed * cos(angle)
  self.dy = speed * sin(angle)
end

-- function EnemyBullet:setVelocity(angle, speed)
--   self.dx = math.cos((math.pi / 180) * angle) * speed
--   self.dy = math.sin((math.pi / 180) * angle) * speed
-- end

function EnemyBullet:hit()
  animations:explosion(self.x, self.y)
  bulletHitSfx:play()
  removeEnemyBullet(self)
end

function EnemyBullet:update()
  self.t += 1
  self.x, self.y = self.x + self.dx, self.y + self.dy
  local x,y,c,l = self:moveWithCollisions(self.x, self.y)

  -- animate bullet
  local i = self.t % 2 == 0 and 1 or 2
  self:setImage(bulletGfx:getImage(i))

  for i=1,l do
    local other = c[i].other
    if other:isa(Player) and not player.dying then
      player:die()
      removeEnemyBullet(self)
    elseif other:isa(SupplyShip) or other.isBalloon then
      other:die()
    elseif other.boundaryName then
      -- hit general boundary collision box (e.g. floor or playerswitch)
      removeEnemyBullet(self)
    end
  end

  if (isOffstage(self.x, self.y, self.width, self.height)) then
    removeEnemyBullet(self)
  end
end

function EnemyBullet.clearAll()
  local s = gfx.sprite.getAllSprites()
  for a=1, #s do
    if s[a]:isa(EnemyBullet) then
      s[a]:remove()
    end
  end
end
