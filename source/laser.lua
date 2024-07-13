local gfx <const> = playdate.graphics
local geometry <const> = playdate.geometry
local sound <const> = playdate.sound
local frameTimer <const> = playdate.frameTimer
local random <const> = math.random
local lineSegment <const> = geometry.lineSegment
local rect <const> = geometry.rect
local sin <const>, cos <const> = math.sin, math.cos

class("Laser").extends(gfx.sprite)

local laserSfx = sound.sampleplayer.new("sounds/laser")
local laserSize = 1200
local camOffset = 120

local laserCache = {}

function removeLaser(laser)
  laser.shootTimer:pause()
  laser.sfx:stop()
  laser:remove()
  laserCache[#laserCache+1] = laser
end

function addLaser(x, y)
  local laser = nil
  if #laserCache > 0 then
    laser = table.remove(laserCache)
  else
    laser = Laser()
  end

  laser.angle = random(1000)>500 and 1.570796 or 0
  laser.originX = x
  laser.originY = y + camOffset
  laser.x1 = laser.originX - cos(laser.angle) * 25
  laser.y1 = laser.originY - sin(laser.angle) * 25
  laser.x2 = laser.originX + cos(laser.angle) * 25
  laser.y2 = laser.originY + sin(laser.angle) * 25
  laser:moveTo(0,-camOffset)
  laser:add()

  laser.shootTimer = frameTimer.new(150, function()
    removeLaser(laser)
  end)

  laser.sfx:play()
  return laser
end

function Laser:setPosition(x,y)
  self.originX = x
  self.originY = y + camOffset
end

function Laser:init()
  Laser.super.init(self)
  self.sfx = laserSfx:copy()
  self:setZIndex(850)
  -- self:setSize(400,240)
  self:setSize(400,480)
  self:moveTo(0,-camOffset)
  self:setCenter(0,0)
  self.lineWidth = random(4,10)
  return self
end

function Laser:update()
  local size = laserSize

  -- mini-lasers pulse, hinting at full laser
  if self.shootTimer.frame < 80 then
    if self.shootTimer.frame % 27 == 0 then
      -- clear out previous laser before changing angle
      self:markDirty()
      self.angle = (self.angle == 1.570796 and 0 or 1.570796)
    end
    size = 25
  end

  self.lineWidth = random(4,10)

  self.x1 = self.originX - cos(self.angle) * size
  self.y1 = self.originY - sin(self.angle) * size
  self.x2 = self.originX + cos(self.angle) * size
  self.y2 = self.originY + sin(self.angle) * size

  -- make sure twitching laser gets cleanly drawn on each frame (playdate wasn't marking area as dirty)
  if self.angle == 0 then
    self.addDirtyRect(self.x1-10, -camOffset+self.y1-self.lineWidth/2, size*2+20, self.lineWidth)
  else
    self.addDirtyRect(self.x1-self.lineWidth/2, -camOffset+self.y1-10, self.lineWidth, size*2+20)
  end


  local lineTest = lineSegment.new(self.x1, self.y1-camOffset, self.x2, self.y2-camOffset)
  local playerBounds = player:getBoundsRect()
  local playerRect = rect.new(player.x - playerBounds.width/2, player.y - playerBounds.height/2, playerBounds.width, playerBounds.height)
  if (lineTest:intersectsRect(playerRect)) then
    player:die()
  end

end

function Laser:draw()
  gfx.setLineCapStyle(gfx.kLineCapStyleRound)
  gfx.setColor(gfx.kColorWhite)
  gfx.setLineWidth(self.lineWidth)
  gfx.drawLine(self.x1, self.y1, self.x2, self.y2)
  gfx.setLineWidth(random(2))
  gfx.setColor(gfx.kColorBlack)
  gfx.drawLine(self.x1, self.y1, self.x2, self.y2)
end

