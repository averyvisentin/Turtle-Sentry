--this script will be used to wrap the Peripheralium hub to the turtle
--this will allow the turtle to use multiple peripherals in one slot


-- Wrap the peripheral hub
local hub = peripheral.wrap("side") -- Replace "left" with the side where the hub is installed

-- Function to check if an item can be used as an upgrade
local function checkUpgrade(slot)
    local isUpgrade = hub.isUpgrade(slot)
    print("Can slot " .. slot .. " be used as an upgrade? " .. tostring(isUpgrade))
end

-- Function to equip an upgrade
local function equipUpgrade(slot)
    local result = hub.equip(slot)
    if result.success then
        print("Upgrade equipped from slot " .. slot)
    else
        print("Failed to equip upgrade from slot " .. slot .. ": " .. result.error)
    end
end

-- Function to list all equipped upgrades
local function listUpgrades()
    local upgrades = hub.getUpgrades()
    if #upgrades > 0 then
        for _, upgrade in ipairs(upgrades) do
            print("Equipped upgrade: " .. upgrade)
        end
    else
        print("No upgrades equipped")
    end
end

-- Example usage
local slot = 1
checkUpgrade(slot)
equipUpgrade(slot)
listUpgrades()
