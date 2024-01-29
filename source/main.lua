import 'CoreLibs/graphics'
import 'CoreLibs/sprites'
-- import 'CoreLibs/input'
import "CoreLibs/timer"

local gfx <const> = playdate.graphics
-- local geo <const> = playdate.geometry
-- local point <const> = geo.point
local timer <const> = playdate.timer

local gfx = playdate.graphics
local s, ms = playdate.getSecondsSinceEpoch()
math.randomseed(ms,s)

import 'player'

local score = 0
local player = create_player()

local function createBackgroundSprite()

  local bg = gfx.sprite.new()
  local bgImg = gfx.image.new('images/background2.png')
  local w, h = bgImg:getSize()
  -- bgH = h
  bg:setBounds(0, 0, 400, 240)

  function bg:draw(x, y, width, height)
    bgImg:draw(0, 0)
    -- bgImg:draw(0, bgY-bgH)
  end

  function bg:update()
    -- bgY += 1
    -- if bgY > bgH then
    --   bgY = 0
    -- end
    -- self:markDirty()
  end

  bg:setZIndex(0)
  bg:add()

end

createBackgroundSprite()
-- player = createPlayer(200, 180)

function playdate.update()

  timer.updateTimers()

  -- if playdate.buttonJustPressed("B") or playdate.buttonJustPressed("A") then
  --   playerFire()
  -- end

  gfx.sprite.update()

  -- gfx.setFont(font)
  -- gfx.drawText('sprite count: '..#gfx.sprite.getAllSprites(), 2, 2)
  -- gfx.drawText('max enemies: '..maxEnemies, 2, 16)
  -- gfx.drawText('score: '..score, 2, 30)

  playdate.drawFPS(2, 224)

end
