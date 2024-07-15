local pd <const> = playdate
local gfx <const> = pd.graphics
local sound <const> = pd.sound
local random <const>, sin <const>, cos <const>, atan2 <const> = math.random, math.sin, math.cos, math.atan2

class("EnemyBullet").extends(gfx.sprite)

local bulletGfx = gfx.imagetable.new("images/enemy-bullet")
local bulletCache = {}
local bulletHitSfx = {
  sound.sampleplayer.new("sounds/crash"),
  sound.sampleplayer.new("sounds/pop")
}

function addEnemyBullet(x, y, angle, speed, type)
  type = type or 1
  local bullet = nil
  if #bulletCache > 0 then
    bullet = table.remove(bulletCache)
    bullet.type = type
  else
    bullet = EnemyBullet(type)
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

  self.type = type or 1
  self:setGroups({1})
  self:setCollidesWithGroups({1,3})
  self:setZIndex(890)
  self.collisionResponse = gfx.sprite.kCollisionTypeOverlap
  local bullet = bulletGfx:getImage(type)
  self:setImage(bullet)
  self:setCollideRect(2,2,12,12) -- todo: set these from a table of different collisions for different bullet types?

  self.isEnemyBullet = true
  self.points = 10

  return self
end

-- set bullet velocity after init
function EnemyBullet:setVelocity(angle, speed)
  self.dx = speed * cos(angle)
  self.dy = speed * sin(angle)
  -- if using degrees...
  -- self.dx = math.cos((math.pi / 180) * angle) * speed
  -- self.dy = math.sin((math.pi / 180) * angle) * speed
end

function EnemyBullet:hit()
  animations:explosion(self.x, self.y)
  bulletHitSfx[self.type]:play()
  removeEnemyBullet(self)
end

function EnemyBullet:update()
  self.x, self.y = self.x + self.dx, self.y + self.dy
  local x,y,c,l = self:moveWithCollisions(self.x, self.y)

  for i=1,l do
    local other = c[i].other
    if other:isa(Player) and not player.dying then
      player:die()
      removeEnemyBullet(self)
    -- elseif other:isa(Block) and not other.broken then
    --   other:hit()
    --   removeEnemyBullet(self)
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
