--this script will be used to wrap the Peripheralium hub to the turtle
--this will allow the turtle to use multiple peripherals in one slot


-- Function to find and wrap the Peripheralium hub
local function findAndWrapHub()
    local sides = {"left", "right", "top", "bottom", "front", "back"}
    for _, side in ipairs(sides) do
        if peripheral.isPresent(side) then
            local type = peripheral.getType(side)
            if type == "netherite_peripheralium_hub" or type == "peripheralium_hub" then
                return peripheral.wrap(side), side
            end
        end
    end
    return nil, nil -- Return nil if no hub is found
end

local hub, hubSide = findAndWrapHub()

if not hub then
    error("Peripheralium hub not found. Please attach the hub to any side of the turtle.")
else
    print("Peripheralium hub found on the " .. hubSide .. " side.")
end

-- Function to check if an item can be used as an upgrade
local function checkUpgrade(slot)
    if hub then
        local isUpgrade = hub.isUpgrade(slot)
        print("Slot " .. slot .. ": Can be used as an upgrade? " .. tostring(isUpgrade))
    end
end

-- Function to equip an upgrade
local function equipUpgrade(slot)
    if hub then
        local result = hub.equip(slot)
        if result and result.success then
            print("Upgrade equipped from slot " .. slot)
        else
            print("Failed to equip upgrade from slot " .. slot .. (result.error and (": " .. result.error) or ""))
        end
    end
end

-- Function to list all equipped upgrades
local function listUpgrades()
    if hub then
        local upgrades = hub.getUpgrades()
        if #upgrades > 0 then
            for _, upgrade in ipairs(upgrades) do
                print("Equipped upgrade: " .. upgrade)
            end
        else
            print("No upgrades equipped.")
        end
    end
end

-- Example usage
local slot = 1
checkUpgrade(slot)
equipUpgrade(slot)
listUpgrades()
