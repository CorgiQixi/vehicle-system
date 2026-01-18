local QBCore = exports['qb-core']:GetCoreObject()
local ESX = nil

-- 检测框架
if GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif GetResourceState('es_extended') == 'started' then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

-- 车辆购买
RegisterServerEvent('vehicle:purchase')
AddEventHandler('vehicle:purchase', function(vehicleId)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    -- 读取车辆数据
    local vehicleData = GetVehicleData(vehicleId)
    if not vehicleData then
        TriggerClientEvent('vehicle:purchaseFailed', src, '车辆数据不存在')
        return
    end
    
    -- 检查玩家资金
    if player.money < vehicleData.price then
        TriggerClientEvent('vehicle:purchaseFailed', src, '资金不足')
        return
    end
    
    -- 扣款
    if not player.removeMoney(vehicleData.price) then
        TriggerClientEvent('vehicle:purchaseFailed', src, '交易失败')
        return
    end
    
    -- 生成车牌
    local plate = GeneratePlate()
    
    -- 车辆属性
    local vehicleProps = {
        model = vehicleData.model,
        plate = plate,
        fuel = 100.0,
        engine = 1000.0,
        body = 1000.0,
        owner = player.identifier,
        price = vehicleData.price,
        stored = false
    }
    
    -- 发送成功事件
    TriggerClientEvent('vehicle:purchaseSuccess', src, vehicleProps)
    
    -- 记录日志
    LogPurchase(src, player.identifier, vehicleData.name, vehicleData.price)
end)

-- 试驾
RegisterServerEvent('vehicle:testDrive')
AddEventHandler('vehicle:testDrive', function(model)
    local src = source
    
    -- 检查冷却时间
    if not CheckCooldown(src, 'testdrive', 300) then -- 5分钟冷却
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            multiline = true,
            args = {"系统", "请等待5分钟后再试驾"}
        })
        return
    end
    
    -- 生成试驾车辆
    local player = GetPlayer(src)
    if player then
        TriggerClientEvent('vehicle:spawnTestDrive', src, model)
    end
end)

-- 保存车辆到数据库
RegisterServerEvent('vehicle:saveVehicle')
AddEventHandler('vehicle:saveVehicle', function(vehicleProps)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    -- 保存到数据库
    MySQL.Async.execute('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (@license, @citizenid, @vehicle, @hash, @mods, @plate, @state)', {
        ['@license'] = player.identifier,
        ['@citizenid'] = player.citizenid or player.identifier,
        ['@vehicle'] = vehicleProps.model,
        ['@hash'] = GetHashKey(vehicleProps.model),
        ['@mods'] = json.encode(vehicleProps),
        ['@plate'] = vehicleProps.plate,
        ['@state'] = 0
    })
end)

-- 获取玩家数据
function GetPlayer(src)
    if QBCore then
        local player = QBCore.Functions.GetPlayer(src)
        if player then
            return {
                identifier = player.PlayerData.license,
                citizenid = player.PlayerData.citizenid,
                money = player.PlayerData.money['cash'] or 0,
                removeMoney = function(amount)
                    return player.Functions.RemoveMoney('cash', amount, 'vehicle-purchase')
                end
            }
        end
    elseif ESX then
        local player = ESX.GetPlayerFromId(src)
        if player then
            return {
                identifier = player.identifier,
                money = player.getMoney(),
                removeMoney = function(amount)
                    return player.removeMoney(amount)
                end
            }
        end
    end
    return nil
end

-- 获取车辆数据
function GetVehicleData(vehicleId)
    local vehicles = LoadVehicles()
    for _, vehicle in ipairs(vehicles) do
        if vehicle.id == vehicleId then
            return vehicle
        end
    end
    return nil
end

-- 加载车辆数据
function LoadVehicles()
    local data = LoadResourceFile(GetCurrentResourceName(), 'cars.json')
    if data then
        return json.decode(data)
    end
    return {}
end

-- 生成车牌
function GeneratePlate()
    local plate = ""
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    for i = 1, 8 do
        local rand = math.random(1, #chars)
        plate = plate .. chars:sub(rand, rand)
    end
    
    return plate
end

-- 检查冷却时间
function CheckCooldown(src, type, cooldownTime)
    local key = src .. '_' .. type
    local lastTime = Cooldowns[key] or 0
    local currentTime = os.time()
    
    if currentTime - lastTime > cooldownTime then
        Cooldowns[key] = currentTime
        return true
    end
    
    return false
end

-- 记录购买日志
function LogPurchase(src, identifier, vehicleName, price)
    MySQL.Async.execute('INSERT INTO vehicle_purchases (player_id, vehicle_name, price, timestamp) VALUES (@player_id, @vehicle_name, @price, @timestamp)', {
        ['@player_id'] = identifier,
        ['@vehicle_name'] = vehicleName,
        ['@price'] = price,
        ['@timestamp'] = os.date('%Y-%m-%d %H:%M:%S')
    })
end

-- 全局变量
Cooldowns = {}

-- 确保数据库表存在
MySQL.ready(function()
    -- 玩家车辆表
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `player_vehicles` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `license` varchar(50) DEFAULT NULL,
            `citizenid` varchar(50) DEFAULT NULL,
            `vehicle` varchar(50) DEFAULT NULL,
            `hash` int(11) DEFAULT NULL,
            `mods` longtext DEFAULT NULL,
            `plate` varchar(50) NOT NULL,
            `state` int(11) DEFAULT 0,
            PRIMARY KEY (`id`),
            KEY `plate` (`plate`),
            KEY `citizenid` (`citizenid`),
            KEY `license` (`license`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])
    
    -- 购买记录表
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `vehicle_purchases` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `player_id` varchar(50) DEFAULT NULL,
            `vehicle_name` varchar(100) DEFAULT NULL,
            `price` int(11) DEFAULT NULL,
            `timestamp` datetime DEFAULT current_timestamp(),
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])
end)