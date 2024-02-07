-- utility miscellany

function math.clamp(a, min, max)
  if min > max then
    min, max = max, min
  end
  return math.max(min, math.min(max, a))
end

-- clamp velocity to min/max if moving (returns 0 if 0, otherwise min/max honoring negatives)
function minMaxVelocity(d,min,max)
  return d == 0 and 0 or (d > 0 and 1 or -1) * math.clamp(math.abs(d), min, max)
end

--ensure min velocity, pos or neg
function caplowVelocity(spd,minV)
  if (spd~=0 and math.abs(spd)<minV) then
    if spd<0 then spd=-minV else spd=minV end
  end
  return spd
end

--ensure max velocity, pos or neg
function capVelocity(spd,maxV)
  if (math.abs(spd)>maxV) then
    if spd<0 then spd=-maxV else spd=maxV end
  end
  return spd
end


-- mimic pico-8s rnd()
function rnd(n)
  n = n or 1
  return (math.random(n)-1 + math.random(1000)/1000)
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
  return t[math.ceil(math.random(#t))]
end
-- Call function for each array element
function table.each( t, fn )
  if type(fn)~="function" then return end
  for _, e in pairs(t) do
    fn(e)
  end
end

-- function normalize(float input)
-- {
--     float average      = (min + max) / 2;
--     float range        = (max - min) / 2;
--     float normalized_x = (input - average) / range;
--     return normalized_x;
-- }
-- double Normalize(val, valmin, valmax, min, max)
-- {
--     return (((val - valmin) / (valmax - valmin)) * (max - min)) + min;
-- }

function normalize(val, max, min)
  return (val - min) / (max - min) * 2 - 1
end
