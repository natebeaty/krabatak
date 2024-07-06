import "CoreLibs/timer"
import "CoreLibs/frameTimer"
import "CoreLibs/graphics"
import "CoreLibs/easing"
import "lib/sequence"
import "utility"
import "player"
import "bullet"
import "building"
import "supply"
import "train"
import "enemy"
import "boss"
import "animations"
import "levels/city"
-- import "level"

-- groups
-- player -> enemy,block,supply,balloon
-- bullet -> enemy,block,supply,balloon
-- enemy -> bullet,player,supply,balloon
-- supply -> player,bullet,enemy
-- balloon -> player,bullet,enemy,block
-- boss -> player,bullet
--
-- 1 = player, enemies, building
-- 2 = broken blocks (no collisions)
-- 3 = supply, balloon
-- 4 = floor borders
-- 5 = change man/plane trigger blocks
-- 6 = boss?

-- space harrier
-- crabcats
-- chicago chomp
-- raptor
-- raid on playville
-- space raid
--

local pd <const> = playdate
local gfx <const> = pd.graphics
local sound <const> = pd.sound
local frameTimer <const> = pd.frameTimer
local font <const> = gfx.font.new("fonts/font-pedallica-fun-18")
local point <const> = pd.geometry.point
local titleGfx = gfx.image.new("images/title")
local gameOverGfx = gfx.image.new("images/game-over")
local heartGfx = gfx.image.new("images/heart")
local blinkTimer = frameTimer.new(10)
local inputPause = 0
local boss1 = nil
blinkTimer.repeats = true

-- betterize random
math.randomseed(pd.getSecondsSinceEpoch())

-- sounds
local musicSfx = sound.sampleplayer.new("sounds/music")
local bonusSfx = sound.sampleplayer.new("sounds/bonus")
local gameOverSfx = sound.sampleplayer.new("sounds/game-over")
local menuActionSfx = sound.sampleplayer.new("sounds/menu-action")
local startGameSfx = sound.sampleplayer.new("sounds/start-game")

-- bonus stage stagger when counting
local bonusStagger = 0
local lastBonusStagger = 2.5

-- set default font
gfx.setFont(font)

function setVerticalScroll(flag)
  verticalScroll = flag
  playerMinY = verticalScroll and -100 or 33
end
function resetCamera()
  cameraY = 0
  city:setY(-120)
end

-- globals
setVerticalScroll(false)
hiscore = 0
cameraY = 0
blinkyBuildings = nil
NW,N,NE,W,E,SW,S,SE = 1,2,3,4,6,7,8,9  -- plane sprite imageTable indexes, also used in Bullet

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
    if mode == "game" then
      self.addDirtyRect(0, 0, 125, 25)
    end
  end
  function status:draw()
    gfx.fillRect(0,0,400,25)
    -- gfx.setColor(gfx.kColorWhite)
    gfx.setImageDrawMode("NXOR")
    gfx.drawText("FUEL: "..math.ceil(player.fuel), 5, 5)
    gfx.drawTextAligned("SCORE: "..player.score, 200, 5, kTextAlignment.center)
    for i=1,player.life do
      heartGfx:draw(395-i*15,6)
    end
    gfx.setImageDrawMode("copy")
  end
  return status
end

-- Initial setup
function setup()
  level = 1
  enemiesKilled = 0
  city = City()
  player = Player()
  player:add()
  supply = Supply()
  train = Train()
  building = Building()
  building:makeBuildings()
  statusBar = setupStatusBar()
  animations = Animations()
  mode = "title"
  musicSfx:play()
end

-- game over, man!
function gameOver()
  inputPause = 30
  gameOverSfx:play()
  mode = "game_over"
  blinkyBuildings = 1
  hiscore = math.max(hiscore, player.score)
  -- dset(0,hiscore) --record hiscore in cartdata
end

-- enemy killed, check level progress
function checkLevel()
  enemiesKilled += 1
  if enemiesKilled >= 5 + 5*(level-1) then
    levelFinished()
  end
end

-- level done!
function levelFinished()
  inputPause = 30
  resetCamera()
  mode = "bonus"
  Enemy:resetAll()
end

-- level passed!
function nextLevel()
  emptyStage()
  blinkyBuildings = nil
  building:reshuffle()
  level += 1
  Enemy:setMax(level)
  player:respawn()
  if level % 3 == 1 then
    city:changeBg("day")
  elseif level % 3 == 2 then
    city:changeBg("dusk")
  elseif level % 3 == 0 then
    city:changeBg("night")
  end
  -- if level == 2 then
  --   Boss:boss1_entry()
  -- else
    mode = "game"
  -- end
end

-- start game from title
function startGame()
  musicSfx:stop()
  inputPause = 30
  startGameSfx:play()
  emptyStage()
  building:clearAll()
  building:makeBuildings()
  pd.graphics.sprite.redrawBackground()
  mode = "game"
end

-- restart after game over
function restart()
  inputPause = 30
  building:clearAll()
  building:makeBuildings()
  player:restart()
  musicSfx:play()
  mode = "title"
  level = 1
  city:changeBg("day")
  Enemy:setMax(level)
  emptyStage()
  -- music(1,2500)
end

function emptyStage()
  enemiesKilled = 0
  building:resetBonus()
  Enemy:resetAll()
  supply:reset()
end

-- set..up..
setup()

-- text with shadow
function shadowText(text, x, y)
  -- Draw text shadow
  gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
  gfx.drawTextAligned(text, x-1, y-1, kTextAlignment.center)
  gfx.drawTextAligned(text, x-1, y+1, kTextAlignment.center)
  gfx.drawTextAligned(text, x+1, y-1, kTextAlignment.center)
  gfx.drawTextAligned(text, x+1, y, kTextAlignment.center)
  gfx.drawTextAligned(text, x+1, y+1, kTextAlignment.center)
  gfx.drawTextAligned(text, x+2, y+2, kTextAlignment.center)
  gfx.drawTextAligned(text, x+3, y+3, kTextAlignment.center)
  -- Draw text
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  gfx.drawTextAligned(text, x, y, kTextAlignment.center)

  gfx.setImageDrawMode("copy")
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
function pd.update()
  if verticalScroll and player.position.y < 120 then
    local cityY = math.min(-player.position.y, 20)
    city:setY(cityY)
    cameraY = cityY + 120
    -- print(player.position.y, cityY, cameraY, -120 - player.position.y + 120)
  end

  gfx.setDrawOffset(0,cameraY)

  gfx.sprite.update()
  sequence.update()
  Boss:update()

  screenShake()

-- 0
-- 100: cityY = -100
-- 120
-- 240

  -- pause input (e.g. after level ends)
  if inputPause > 0 then inputPause-=1 end

  if mode == "title" then

    Enemy:checkSpawn()
    titleGfx:draw(100, 40)
    if inputPause==0 then
      buttonText("Ⓐ START", 200, 135)
      if pd.buttonJustPressed("A") then
        menuActionSfx:play()
        startGame()
      end
    end

  elseif mode == "game" then

    Enemy:checkSpawn()
    if player.mode == "man" then
      drawPlane()
    end

  elseif mode == "game_over" then

    gameOverGfx:draw(150, 40)
    if inputPause==0 then
      buttonText("Ⓐ RESTART", 200, 120)
      if pd.buttonJustPressed("A") then
        menuActionSfx:play()
        restart()
      end
    end

  elseif mode == "bonus" then

    shadowText("LEVEL "..level.." COMPLETE", 200, 50)

    -- tally bonus points
    if pd.buttonJustPressed("A") and lastBonusStagger < 2.25 then
      lastBonusStagger = 0
    end
    if bonusStagger<=0 then
      if building:checkBonus() then
        if lastBonusStagger > 0.1 then
          bonusStagger = lastBonusStagger
          lastBonusStagger = lastBonusStagger/1.025
        end
        bonusSfx:play()
      else
        blinkyBuildings = 1
        buttonText("Ⓐ NEXT LEVEL", 200, 85)
        if inputPause==0 and pd.buttonJustPressed("A") then
          menuActionSfx:play()
          nextLevel()
        end
        lastBonusStagger = 2.5
      end
    else
      bonusStagger -= 1
    end

    if not blinkyBuildings and blinkTimer.frame < 5 then
      shadowText("BONUS POINTS", 200, 75)
    end

  end

  frameTimer.updateTimers()
  pd.drawFPS(2, 224)

end
