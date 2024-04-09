import "CoreLibs/timer"
import "CoreLibs/frameTimer"
import "CoreLibs/graphics"
import "CoreLibs/easing"
import "lib/sequence"
import "utility"
import "bossBullet"

local pd <const> = playdate
local gfx <const> = pd.graphics
local sound <const> = pd.sound
local point <const> = pd.geometry.point
local easing <const> = pd.easingFunctions
local frameTimer <const> = pd.frameTimer
local random,floor <const> = math.random,math.floor

class("Boss").extends()
class("Boss1").extends(gfx.sprite)

local boss1ImagesTable = gfx.imagetable.new("images/boss1")
local boss1HeadGfx = gfx.image.new("images/boss1-head-nodrill")
local boss1EyeGfx = gfx.image.new("images/boss1-eye")
local boss1NeckGfx = gfx.image.new("images/boss1-neck")
local warningGfx = gfx.image.new("images/warning")
local explodingDebrisGfx = gfx.image.new("images/exploding-debris")

local crashSfx = sound.sampleplayer.new("sounds/crash")
local hornSfx = sound.sampleplayer.new("sounds/horn")
local buildingCollapseSfx = sound.sampleplayer.new("sounds/building-collapse")

-- boss1 anim sequences
local boss1_shoot_sequence = sequence.new():from(1):to(179, 5, "outQuad"):callback(function()
  if not boss1.dying then
    bossShoot()
  end
end)
function bossShoot()
  boss1_shoot_sequence:stop()
  boss1_shoot_sequence:start()
end
local boss1_head_sequence = sequence.new():from(260):to(70, 0.75, "outQuad"):callback(function()
  boss1.hasEntered = 1
  local xt = frameTimer.new(50, -20, 20, easing.inOutQuad)
  xt.reverses = true
  xt.repeats = true
  xt.updateCallback = function(timer)
    -- boss1.position.x = 200 + floor(timer.value)
  end
  local yt = frameTimer.new(100, 0, 40, easing.inOutQuad)
  yt.reverses = true
  yt.repeats = true
  yt.updateCallback = function(timer)
    -- print(timer.value, floor(timer.value))
    boss1.position.y = 80 + floor(timer.value)
    -- print("bpy", boss1.position.y)
  end
end)
local boss1_entry_sequence = sequence.new():from(1):to(100, 1, "outQuad"):callback(function()
  stopShake()
  buildingCollapseSfx:setVolume(1)
  buildingCollapseSfx:play()
  setVerticalScroll(true)
  boss1_head_sequence:start()
  boss1_shoot_sequence:start()
  mode = "boss1"
end)

-- death sequence multiple explosion groups
local deathExplosionOffset = 30
local numDeathExplosions = 5

local boss1_death_sequence = sequence.new():from(0):sleep(0.5):callback(function(t)
  crashSfx:play()
  for i=1,numDeathExplosions do
    Animations:explosion(boss1.position.x - deathExplosionOffset + random(deathExplosionOffset*2), boss1.position.y - deathExplosionOffset + random(deathExplosionOffset*2), i % 3 == 0 and "lg" or "sm")
  end
  print("nl", t.numLoops)
  if t.numLoops > 3 then
    boss1:remove()
    boss1.eyeBall:remove()
    levelFinished()
    t:stop()
    setVerticalScroll(false)
  end
end):loop()

function Boss1:init()
  Boss1.super.init(self)

  self:setImage(boss1ImagesTable:getImage(1))
  self:setZIndex(1000)
  self:setCollideRect(16,16,42,66)
  -- self:setCollideRect(26,40,22,15)
  self:setGroups({1})
  self:setCollidesWithGroups({1})
  -- self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

  self.stepTimer = frameTimer.new(6)
  self.stepTimer.repeats = true
  self.directionTimer = frameTimer.new(random(50)+100, function()
    self:changeDirection()
  end)
  self.directionTimer.repeats = true

  self.position = point.new(200,320)
  self:moveTo(self.position)

  self.isBoss = true
  self.points = 1000
  self.life = 5
  self.hitPoints = 20

  self.eyeBall = gfx.sprite.new(boss1EyeGfx)
  self.eyeBall.parent = self
  self.eyeBall.isBossTarget = true
  self.eyeBall:setZIndex(1000)
  self.eyeBall:setCollideRect(0,0,boss1EyeGfx:getSize())
  self.eyeBall:setGroups({1})
  self.eyeBall:setCollidesWithGroups({1})

  -- make eyeball follow player
  function self.eyeBall:update()
    local x = self.parent.x
    local y = self.parent.y+5
    if player.x < self.parent.x then
      x -= 4
    elseif player.x > self.parent.x + 40 then
      x += 4
    end
    self:moveTo(x,y)
  end

  self:add()
  self.eyeBall:add()
end

function Boss1:changeDirection(s)
  self.directionTimer.duration = random(50)+100
  self.directionTimer:reset()
  -- print("boss1.changeDirection")
  -- local dx, dy = (rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75, (rnd()) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75
  -- if self.position.y>50 then
  --   dy=(rnd(2)-1) * (enemySpeed * enemySpeed * 49/10000+1) * 0.75
  -- end
  -- self.velocity = vector2D.new(dx, dy)
end

function Boss1:hit(x,y)
  self.life -= 1
  Animations:explosion(x, y)
  crashSfx:play()
  player:addScore(self.hitPoints)
  if self.life == 0 then
    self:die()
  end
end
function Boss1:die()
  self.dying = true
  boss1_death_sequence:start()
end

function Boss1:update()

  if mode == "boss1" then

    if not boss1.hasEntered then
      -- sliding head up from offscreen
      boss1.position.y = floor(boss1_head_sequence:get())
    end

    local shootAngle = floor(boss1_shoot_sequence:get())
    if shootAngle % 13 == 0 then
      addBossBullet(shootAngle % 12 == 0 and "sm" or "lg", boss1.x, boss1.y, shootAngle, 2)
    end

  elseif mode == "boss1_entry" then

    local n = floor(boss1_entry_sequence:get())

    -- WARNING horn blare
    if n == 40 or n == 80 then
      hornSfx:play()
    end
    if hornSfx:isPlaying() then
      warningGfx:draw(0, 80)
    end

    -- slowly increase screen shake
    if n % 10 == 0 then
      setScreenShake(n/250,1)
      buildingCollapseSfx:setVolume(n/100)
      buildingCollapseSfx:play()
    end

  end

  self:moveTo(self.position)

end
boss1 = Boss1()


-----------------
-- static methods


-- boss 1 intro
function Boss:boss1_entry()
  mode = "boss1_entry"
  boss1_entry_sequence:start()
end

-- global boss update loop
function Boss:update()
end
