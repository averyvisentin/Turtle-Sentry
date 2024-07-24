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
    if turtle.refuel(10) then
      print("[*] Refueled successfully.")
    else
      print("[!] Failed to refuel. Halting operation.")
      return false
    end
  end
  return true
end

function getRandomDirection()
  return math.random(2) == 1 and 2 or -2
end

-- Scan surroundings for blocks within a radius of 20
function scanSurroundings()
  local scanner = peripheral.wrap("universal_scanner")
  if not scanner then
    print("[!] Universal scanner not found.")
    return nil
  end
  local blocks = scanner.scan("block", 8)
  local blockMap = {}
  for i, block in ipairs(blocks) do
    blockMap[block.x .. ',' .. block.y .. ',' .. block.z] = true
    if i % 10 == 0 then -- Yield every 10 iterations
      os.sleep(0.5)
    end
  end
  return blockMap
end

function getNeighbors(node, blockMap)
  local neighbors = {}
  local directions = {
    {dx = 0, dy = 1, dz = 0},  -- up
    {dx = 0, dy = -1, dz = 0}, -- down
    {dx = 0, dy = 0, dz = -1}, -- north
    {dx = 0, dy = 0, dz = 1},  -- south
    {dx = 1, dy = 0, dz = 0},  -- east
    {dx = -1, dy = 0, dz = 0}  -- west
  }
  for _, dir in ipairs(directions) do
    local neighbor = {
      x = node.x + dir.dx,
      y = node.y + dir.dy,
      z = node.z + dir.dz
    }
    if not blockMap[neighbor.x .. ',' .. neighbor.y .. ',' .. neighbor.z] then
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

function turnTo(targetDirection)
  local currentDirection = getCurrentDirection() -- You need to implement this based on your orientation tracking
  local turnRightTimes = (targetDirection - currentDirection + 4) % 4
  for i = 1, turnRightTimes do
      turtle.turnRight()
  end
end

function goTo(targetX, targetY, targetZ)
  local currentX, currentY, currentZ = gps.locate()
  -- Move vertically first
  while currentY < targetY do
      turtle.up()
      currentY = currentY + 1
  end
  while currentY > targetY do
      turtle.down()
      currentY = currentY - 1
  end
  -- Move horizontally
  while currentX ~= targetX or currentZ ~= targetZ do
      if currentX < targetX then
          turnTo(1) -- Assuming 0 is north, 1 is east, 2 is south, 3 is west
          turtle.forward()
          currentX = currentX + 1
      elseif currentX > targetX then
          turnTo(3)
          turtle.forward()
          currentX = currentX - 1
      end
      if currentZ < targetZ then
          turnTo(0)
          turtle.forward()
          currentZ = currentZ + 1
      elseif currentZ > targetZ then
          turnTo(2)
          turtle.forward()
          currentZ = currentZ - 1
      end
  end
end

-- Open modem
local modem = peripheral.find("modem") or peripheral.wrap("modem")
if modem then
  rednet.open("modem")
end
if rednet.isOpen("modem") then
  print("[*] Modem is ready, waiting for master.")
  print("[*] My computer ID: " .. tostring(os.getComputerID()))

  while true do
    local senderId, message, protocol = rednet.receive(receiveProtocol, 60)
    if not senderId then
      print("[!] No message received. Retrying...")
      os.sleep(1)
      goto continue
    end

    local masterLocation = split(message)
    local masterPos = vector.new(masterLocation[1], masterLocation[2], masterLocation[3])

    local mePos = vector.new(gps.locate())

    local goal = {
      x = masterPos.x + getRandomDirection(),
      y = masterPos.y,
      z = masterPos.z + getRandomDirection()
    }

    local blockMap = scanSurroundings()
    if not blockMap then
      print("[!] Failed to scan surroundings. Retrying...")
      os.sleep(1)
      goto continue
    end

    local path = aStar({x = mePos.x, y = mePos.y, z = mePos.z}, goal, blockMap)

    if path then
      for _, step in ipairs(path) do
        goTo(step.x, step.y, step.z)
      end

      local scanner = peripheral.wrap("universal_scanner")
      while true do
        local entities = scanner.scan("entity", 16)
        for _, entity in pairs(entities) do
          if entity.type ~= "player" then
            local yaw = math.deg(math.atan2(entity.z - mePos.z, entity.x - mePos.x))
            local pitch = math.deg(math.atan2(entity.y - mePos.y, math.sqrt((entity.x - mePos.x)^2 + (entity.z - mePos.z)^2)))
            local potency = 5
            peripheral.call("plethora:laser", "fire", yaw, pitch, potency)
          end
        end
        os.sleep(0.5)  -- Adjust this interval based on how frequently you want to re-scan
      end
    else
      print("No path found to the goal.")
    end

    ::continue::
  end
end
