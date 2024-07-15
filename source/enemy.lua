import "puffer"
import "crab"
import "bishop"
import "jellyfish"
import "enemyBullet"

class("Enemy").extends()

local point <const> = playdate.geometry.point
local rect <const> = playdate.geometry.rect
local vector2D <const> = playdate.geometry.vector2D
local frameTimer <const> = playdate.frameTimer
local random <const>, sin <const>, cos <const>, atan2 <const> = math.random, math.sin, math.cos, math.atan2

enemyMinX = -20
enemyMaxX = 420
enemyMaxY = 190

crabs = {}
gremlins = {}
bishops = {}
puffers = {}
jellyfish = {}
maxEnemies = 1


-- set max enemies
function Enemy.setMax(n)
  maxEnemies = n
end

-- clear all enemies
function Enemy.clearAll()
  for a=1, #crabs do
    removeCrab(crabs[a])
  end
  for a=1, #gremlins do
    gremlins[a]:remove()
  end
  for a=1, #bishops do
    removeBishop(bishops[a])
  end
  for a=1, #puffers do
    removePuffer(puffers[a])
  end
  for a=1, #jellyfish do
    removeJellyfish(jellyfish[a])
  end
  -- clear out on-screen crabs
  crabs = {}
  gremlins = {}
  bishops = {}
  puffers = {}
  jellyfish = {}
end

function Enemy.checkSpawn()
  -- spawn crabs
  if (#crabs < (day == 1 and maxEnemies or maxEnemies/2) and rnd()>0.98) then
    local point = point.new(rnd(400), -cameraY + 10)
    local enemy = addCrab(point)
    enemy:add()
    add(crabs, enemy)
  end

  -- spawn bishops
  if (day > 1 and #bishops < (day == 2 and maxEnemies/2 or maxEnemies/3) and rnd()>0.98) then
    local point = point.new(rnd(400), -cameraY + 10)
    local enemy = addBishop(point)
    enemy:add()
    add(bishops, enemy)
  end

  -- spawn puffers
  if (day > 2 and #puffers < (day == 2 and maxEnemies/3 or maxEnemies/4) and rnd()>0.98) then
    local point = point.new(rnd(400), -cameraY + 10)
    local enemy = addPuffer(point)
    enemy:add()
    add(puffers, enemy)
  end

  -- spawn jellyfish
  if (day > 0 and #jellyfish < (day == 2 and maxEnemies/3 or maxEnemies/4) and rnd()>0.98) then
    local leftOfScreen = random(1000)>500 and -1 or 1
    local point = point.new((leftOfScreen > 0 and -10 or 410), -cameraY + random(50,150))
    local velocity = vector2D.new(leftOfScreen*(rnd(1)+1.15), rnd(1)+0.75)
    local enemy = addJellyfish(point, velocity)
    enemy:add()
    add(jellyfish, enemy)
  end
end
