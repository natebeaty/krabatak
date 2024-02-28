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
local font <const> = gfx.font.new("images/font/Sasser-Slab-Bold")
local point <const> = playdate.geometry.point
local titleGfx = gfx.image.new("images/title")
local gameOverGfx = gfx.image.new("images/game-over")
local blinkTimer = frameTimer.new(6)
blinkTimer.repeats = true

gfx.setFont(font)
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
end

function nextLevel()
  emptyStage()
  blinkyBuildings = nil
  level += 1
  Enemy:setMax(level * 2)
  player:respawn()
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

setup()

-- big ol' update loop
function playdate.update()
  gfx.sprite.update()

  if mode == "title" then

    titleGfx:draw(100, 40)
    if playdate.buttonJustPressed("A") then
      mode = "game"
    end

  elseif mode == "game" then

    shakeItNow()
    Crab:checkSpawn()

    if verticalScroll and player.position.y < 120 then
      city:setY(-240 - player.position.y + 120)
      cameraY = 120-player.position.y
    end

  elseif mode == "game_over" then

    gameOverGfx:draw(150, 40)
    if playdate.buttonJustPressed("A") then
      restart()
    end

  elseif mode == "bonus" then

    gfx.drawTextAligned("LEVEL "..level.." COMPLETE", 200, 50, kTextAlignment.center)

    -- tally bonus points
    if (building:checkBonus()) then
      if blinkTimer.frame < 3 then
        gfx.drawTextAligned("BONUS POINTS", 200, 75, kTextAlignment.center)
      end
    else
      blinkyBuildings = 1
      if playdate.buttonJustPressed("A") then
        nextLevel()
      end
    end

  end

  gfx.setDrawOffset(0,cameraY)
  frameTimer.updateTimers()
  -- playdate.drawFPS(2, 224)

end
