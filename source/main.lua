import "CoreLibs/timer"
import "CoreLibs/frameTimer"
import "CoreLibs/graphics"
import "CoreLibs/easing"
import "utility"
import "player"
import "bullet"
import "building"
import "supply"
import "train"
import "enemy"
import "animations"
import "levels/city"
-- import "level"

-- groups
-- player (1) -> enemy,block,supply,balloon
-- bullet -> enemy,block,supply,balloon
-- enemy -> bullet,player,supply,balloon
-- supply -> player,bullet,enemy
-- balloon -> player,bullet,enemy,block
--
-- 1 = player, enemies, building
-- 2 = broken blocks (no collisions)
-- 3 = supply, balloon
-- 4 = floor borders
-- 5 = change man/plane trigger blocks

-- betterize random
math.randomseed(playdate.getSecondsSinceEpoch())

local gfx <const> = playdate.graphics
local frameTimer <const> = playdate.frameTimer
local font <const> = gfx.font.new("fonts/font-pedallica-fun-18")
local point <const> = playdate.geometry.point
local titleGfx = gfx.image.new("images/title")
local gameOverGfx = gfx.image.new("images/game-over")
local blinkTimer = frameTimer.new(8)
blinkTimer.repeats = true

gfx.setFont(font)

-- globals
verticalScroll = false
cameraY = 0
shakeit = 0
hiscore = 0
blinkyBuildings = nil

--ye olde screen rattle
function shakeItNow()
  local fade = 0.95
  local offsetX= 16-rnd(32)
  local offsetY= 16-rnd(32)
  offsetX *= shakeit
  offsetY *= shakeit

  playdate.display.setOffset(offsetX, offsetY)
  shakeit *= fade
  if shakeit < 0.05 then
    shakeit = 0
  end
end

-- Status bar on top with fuel, score, lives
function setupStatusBar()
  local status = gfx.sprite:new()
  status:setIgnoresDrawOffset(true)
  status:setZIndex(1000)
  status:moveTo(0,0)
  status:setCenter(0, 0) -- set center point to left bottom
  status:setSize(400,25)
  status:add()
  function status:update()
    -- fuel update area
    self.addDirtyRect(0, 0, 125, 25)
  end
  function status:draw()
    gfx.fillRect(0,0,400,25)
    -- gfx.setColor(gfx.kColorWhite)
    gfx.setImageDrawMode("NXOR")
    gfx.drawText("FUEL: "..math.ceil(player.fuel), 5, 5)
    gfx.drawTextAligned("SCORE: "..player.score, 200, 5, kTextAlignment.center)
    local heart = gfx.image.new("images/heart")
    for i=1,player.life do
      heart:draw(395-i*15,6)
    end
    gfx.setImageDrawMode("copy")
  end
  return status
end

-- Initial setup
function setup()
  level = 1
  enemiesKilled = 0
  player = Player()
  player:addSprite()
  city = City()
  supply = Supply()
  train = Train()
  building = Building()
  building:makeBuildings()
  statusBar = setupStatusBar()
  animations = Animations()
  mode = "title"
end

-- game over, man!
function gameOver()
  mode = "game_over"
  blinkyBuildings = 1
  hiscore = math.max(hiscore, player.score)
  -- dset(0,hiscore) --record hiscore in cartdata
  level = 1
  -- sfx(04)
end

-- enemy killed, check level progress
function checkLevel()
  enemiesKilled += 1
  if enemiesKilled >= 2 + 16*(level-1) then
    levelFinished()
  end
end

-- level done!
function levelFinished()
  -- need to clean anything up? reset player?
  mode = "bonus"
  Enemy:resetAll()
end

-- level passed!
function nextLevel()
  emptyStage()
  blinkyBuildings = nil
  level += 1
  Enemy:setMax(level * 2)
  player:respawn()
  mode = "game"
end

-- start game from title
function startGame()
  emptyStage()
  building:reset()
  building:makeBuildings()
  playdate.graphics.sprite.redrawBackground()
  mode = "game"
end

-- restart after game over
function restart()
  building:reset()
  building:makeBuildings()
  player:restart()
  mode = "title"
  emptyStage()
  -- music(1,2500)
end

function emptyStage()
  enemiesKilled = 0
  building:resetBonus()
  Enemy:resetAll()
  supply:reset()
end

-- vertical scroll
function setCameraY(y)
  y = y or -240
  cameraY = 0
  city:setY(y)
end


-- set..up..
setup()

-- text with shadow
function shadowText(text, x, y)
  gfx.setImageDrawMode("inverted")
  gfx.drawTextAligned(text, x-1, y-1, kTextAlignment.center)
  gfx.drawTextAligned(text, x+1, y+1, kTextAlignment.center)
  gfx.drawTextAligned(text, x+2, y+2, kTextAlignment.center)
  gfx.drawTextAligned(text, x+3, y+3, kTextAlignment.center)
  gfx.setImageDrawMode("copy")
  gfx.drawTextAligned(text, x, y, kTextAlignment.center)
end

-- rounded button with centered text
function buttonText(text, x, y)
  local h = font:getHeight()
  local w = font:getTextWidth(text)
  local buttonX = x-(w+31)/2
  local buttonY = y-3
  gfx.setColor(gfx.kColorWhite)
  gfx.setLineWidth(8)
  gfx.drawRoundRect(buttonX, buttonY, w+30, h+4, 5)
  gfx.setColor(gfx.kColorBlack)
  gfx.setLineWidth(4)
  gfx.setImageDrawMode("inverted")
  gfx.drawRoundRect(buttonX, buttonY, w+30, h+4, 5)
  gfx.fillRect(buttonX, buttonY, w+30, h+4)
  gfx.drawTextAligned(text, x, y, kTextAlignment.center)
  gfx.setImageDrawMode("copy")
end


-- big ol' update loop
function playdate.update()
  gfx.sprite.update()

  if mode == "title" then

    shakeItNow()
    Enemy:checkSpawn()
    titleGfx:draw(100, 40)
    buttonText("Ⓐ START", 200, 135)
    if playdate.buttonJustPressed("A") then
      startGame()
    end

  elseif mode == "game" then

    shakeItNow()
    Enemy:checkSpawn()

    if verticalScroll and player.position.y < 120 then
      city:setY(-240 - player.position.y + 120)
      cameraY = 120-player.position.y
    end

  elseif mode == "game_over" then

    gameOverGfx:draw(150, 40)
    buttonText("Ⓐ RESTART", 200, 120)
    if playdate.buttonJustPressed("A") then
      restart()
    end

  elseif mode == "bonus" then

    shadowText("LEVEL "..level.." COMPLETE", 200, 50)

    -- tally bonus points
    if (building:checkBonus()) then
      if blinkTimer.frame < 4 then
        shadowText("BONUS POINTS", 200, 75)
      end
    else
      blinkyBuildings = 1
      buttonText("Ⓐ NEXT LEVEL", 200, 85)
      if playdate.buttonJustPressed("A") then
        nextLevel()
      end
    end

  end

  gfx.setDrawOffset(0,cameraY)
  frameTimer.updateTimers()
  -- playdate.drawFPS(2, 224)

end
