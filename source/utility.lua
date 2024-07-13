-- utility miscellany

local min <const>, max <const>, abs <const>, random <const>, ceil <const> = math.min, math.max, math.abs, math.random, math.ceil
local distanceToPoint <const> = playdate.geometry.distanceToPoint

local function clamp(a, b, c)
  if b > c then
    b, c = c, b
  end
  return max(b, min(c, a))
end

-- clamp velocity to min/max if moving (returns 0 if 0, otherwise min/max honoring negatives)
function minMaxVelocity(d,a,b)
  return d == 0 and 0 or (d > 0 and 1 or -1) * clamp(abs(d), a, b)
end

--ensure min velocity, pos or neg
function caplowVelocity(spd,minV)
  if (spd~=0 and abs(spd)<minV) then
    if spd<0 then spd=-minV else spd=minV end
  end
  return spd
end

--ensure max velocity, pos or neg
function capVelocity(spd,maxV)
  if (abs(spd)>maxV) then
    if spd<0 then spd=-maxV else spd=maxV end
  end
  return spd
end


-- mimic pico-8s rnd()
function rnd(n)
  n = n or 1
  return (random(n)-1 + random(1000)/1000)
end

--zero pad a number
function pad(string, length)
  string=""..string
  if (#string == length) then return string end
  return "0"..pad(string, length-1)
end

-- mimic pico-8s del()
function del(t, el)
  local i = table.indexOfElement(t,el)
  if i then
    table.remove(t,i)
  end
end

-- mimic pico-8s add()
function add(t, el)
  table.insert(t, el)
end


-- Random Element in a table
function table.random(t)
  if type(t)~="table" then return nil end
  return t[ceil(random(#t))]
end

-- Call function for each array element
function table.each(t, fn)
  if type(fn)~="function" then return end
  for _, e in pairs(t) do
    fn(e)
  end
end

function normalize(val, a, b)
  return (val - b) / (a - b) * 2 - 1
end

-- distance between center points of two sprites
function closeness(one, other)
  return distanceToPoint(one.x, one.y, other.x, other.y)
end

function isOffstage(x,y,w,h)
  return x < -w or x > 400+w or y < -cameraY+30-h or y > 240+h
end
