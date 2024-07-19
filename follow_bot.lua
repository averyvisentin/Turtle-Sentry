-- Constants
receiveProtocol = "follow_master"
fuelSlot = 16
fuelThreshold = 10

-- Util functions
function isEmpty(s)
  return (s == nil or s == "")
end

function split(str)
  local chunks = {}
  for substring in str:gmatch("%S+") do
    table.insert(chunks, substring)
  end
  return chunks
end

-- General turtle functions
function checkFuel()
  if turtle.getFuelLevel() <= fuelThreshold then
    turtle.select(fuelSlot)
    turtle.refuel(10)
  end
end

function getRandomDirection()
  return math.random(2) == 1 and 2 or -2
end

-- Scan surroundings for blocks within a radius of 20
function scanSurroundings()
  local scanner = peripheral.wrap("left")
  local blocks = scanner.scan("block", 16)
  local blockMap = {}
  for _, block in ipairs(blocks) do
    blockMap[block.x .. ',' .. block.y .. ',' .. block.z] = true
  end
  return blockMap
end

function getNeighbors(node, blockMap)
  local neighbors = {}
  for _, dir in ipairs({'up', 'down', 'north', 'south', 'east', 'west'}) do
    local dx, dy, dz = 0, 0, 0
    if dir == 'up' then dy = 1 elseif dir == 'down' then dy = -1
    elseif dir == 'north' then dz = -1 elseif dir == 'south' then dz = 1
    elseif dir == 'east' then dx = 1 elseif dir == 'west' then dx = -1 end

    if not blockMap[(node.x + dx) .. ',' .. (node.y + dy) .. ',' .. (node.z + dz)] then
      local neighbor = {
        x = node.x + dx,
        y = node.y + dy,
        z = node.z + dz
      }
      table.insert(neighbors, neighbor)
    end
  end
  return neighbors
end

function lowestFScore(openSet, fScore)
  local lowest, bestNode = math.huge, nil
  for _, node in ipairs(openSet) do
    local f = fScore[node.x .. ',' .. node.y .. ',' .. node.z] or math.huge
    if f < lowest then
      lowest, bestNode = f, node
    end
  end
  return bestNode
end

function reconstructPath(cameFrom, current)
  local path = {current}
  while cameFrom[current.x .. ',' .. current.y .. ',' .. current.z] do
    current = cameFrom[current.x .. ',' .. current.y .. ',' .. current.z]
    table.insert(path, 1, current)
  end
  return path
end

function distance(a, b)
  return math.abs(a.x - b.x) + math.abs(a.y - b.y) + math.abs(a.z - b.z)
end

function aStar(start, goal, blockMap)
  local openSet = {start}
  local cameFrom = {}
  local gScore = {[start.x .. ',' .. start.y .. ',' .. start.z] = 0}
  local fScore = {[start.x .. ',' .. start.y .. ',' .. start.z] = distance(start, goal)}

  while #openSet > 0 do
    local current = lowestFScore(openSet, fScore)
    if current.x == goal.x and current.y == goal.y and current.z == goal.z then
      return reconstructPath(cameFrom, current)
    end

    for i, node in ipairs(openSet) do
      if node.x == current.x and node.y == current.y and node.z == current.z then
        table.remove(openSet, i)
        break
      end
    end

    for _, neighbor in ipairs(getNeighbors(current, blockMap)) do
      local tentativeGScore = gScore[current.x .. ',' .. current.y .. ',' .. current.z] + 1
      if tentativeGScore < (gScore[neighbor.x .. ',' .. neighbor.y .. ',' .. neighbor.z] or math.huge) then
        cameFrom[neighbor.x .. ',' .. neighbor.y .. ',' .. neighbor.z] = current
        gScore[neighbor.x .. ',' .. neighbor.y .. ',' .. neighbor.z] = tentativeGScore
        fScore[neighbor.x .. ',' .. neighbor.y .. ',' .. neighbor.z] = tentativeGScore + distance(neighbor, goal)

        local isInOpenSet = false
        for _, node in ipairs(openSet) do
          if node.x == neighbor.x and node.y == neighbor.y and node.z == neighbor.z then
            isInOpenSet = true
            break
          end
        end
        if not isInOpenSet then
          table.insert(openSet, neighbor)
        end
      end
    end
  end
  return nil -- No path found
end

-- Open modem
modemSide = ...
if isEmpty(modemSide) then
  modemSide = "right"
end
rednet.open(modemSide)

if rednet.isOpen(modemSide) then
  print("[*] Modem is ready, waiting for master.")
  print("[*] My computer ID: " .. tostring(os.getComputerID()))

  while true do
    checkFuel()

    senderId, message, protocol = rednet.receive(receiveProtocol)
    masterLocation = split(message)
    masterPos = vector.new(masterLocation[1], masterLocation[2], masterLocation[3])

    mePos = vector.new(gps.locate())

    goal = {
      x = masterPos.x + getRandomDirection(),
      y = masterPos.y,
      z = masterPos.z + getRandomDirection()
    }

    blockMap = scanSurroundings()
    path = aStar({x = mePos.x, y = mePos.y, z = mePos.z}, goal, blockMap)

    if path then
      for _, step in ipairs(path) do
        turtle.goTo(step.x, step.y, step.z)
      end

      local scanner = peripheral.wrap("left")
      while true do
        local entities = scanner.scan("entity", 20)
        for _, entity in pairs(entities) do
          if entity.type ~= "player" then
            local yaw = math.deg(math.atan2(entity.z - mePos.z, entity.x - mePos.x))
            local pitch = math.deg(math.atan2(entity.y - mePos.y, math.sqrt((entity.x - mePos.x)^2 + (entity.z - mePos.z)^2)))
            local potency = 5
            peripheral.call("plethora:laser", "fire", yaw, pitch, potency)
          end
        end
        sleep(0.5)  -- Adjust this interval based on how frequently you want to re-scan
      end
    else
      print("No path found to the goal.")
    end
  end
end
