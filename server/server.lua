local vehiclesData = {}

-- 加载车辆数据
Citizen.CreateThread(function()
    local data = LoadResourceFile(GetCurrentResourceName(), "cars.json")
    if data then
        vehiclesData = json.decode(data)
        print("^2[车辆系统] 已加载 " .. #vehiclesData .. " 辆车辆数据^0")
    else
        print("^1[车辆系统] 错误: 无法加载 cars.json 文件^0")
        -- 创建默认车辆数据
        vehiclesData = {
            {
                id = 1,
                model = "adder",
                name = "Truffade Adder",
                price = 1000000,
                category = "Super",
                maxSpeed = 120,
                acceleration = 9.5,
                seats = 2,
                description = "极速超级跑车，适合追求速度的玩家",
                image = "adder.png"
            },
            {
                id = 2,
                model = "zentorno",
                name = "Pegassi Zentorno",
                price = 750000,
                category = "Super",
                maxSpeed = 118,
                acceleration = 9.2,
                seats = 2,
                description = "经典超级跑车，平衡性能与价格",
                image = "zentorno.png"
            }
        }
    end
end)

-- 获取车辆数据
RegisterServerEvent('vehicle:getVehicleData')
AddEventHandler('vehicle:getVehicleData', function(vehicleId, cb)
    local src = source
    for _, vehicle in ipairs(vehiclesData) do
        if vehicle.id == vehicleId then
            cb(vehicle)
            return
        end
    end
    cb(nil)
end)

-- 通过模型获取车辆数据
RegisterServerEvent('vehicle:getVehicleDataByModel')
AddEventHandler('vehicle:getVehicleDataByModel', function(model, cb)
    for _, vehicle in ipairs(vehiclesData) do
        if vehicle.model == model then
            cb(vehicle)
            return
        end
    end
    cb(nil)
end)

-- 客户端请求车辆数据
RegisterServerEvent('vehicle:requestVehicleData')
AddEventHandler('vehicle:requestVehicleData', function()
    local src = source
    TriggerClientEvent('vehicle:receiveVehicleData', src, vehiclesData)
end)

-- 获取所有车辆数据
RegisterServerEvent('vehicle:getAllVehicles')
AddEventHandler('vehicle:getAllVehicles', function(cb)
    cb(vehiclesData)
end)

-- 检查车辆是否可购买
RegisterServerEvent('vehicle:checkPurchase')
AddEventHandler('vehicle:checkPurchase', function(vehicleId, cb)
    local vehicle = nil
    
    for _, v in ipairs(vehiclesData) do
        if v.id == vehicleId then
            vehicle = v
            break
        end
    end
    
    if not vehicle then
        cb(false, "车辆不存在")
        return
    end
    
    cb(true, vehicle)
end)

-- 添加车辆命令（管理命令）
RegisterCommand('addcar', function(source, args, rawCommand)
    if source ~= 0 then
        print("^1[车辆系统] 此命令仅限控制台使用^0")
        return
    end
    
    if #args < 3 then
        print("^1用法: addcar [模型] [名称] [价格] [类别]^0")
        return
    end
    
    local model = args[1]
    local name = args[2]
    local price = tonumber(args[3])
    local category = args[4] or "Sports"
    
    -- 检查模型是否存在
    if not IsModelInCdimage(model) then
        print("^1错误: 模型 '" .. model .. "' 不存在^0")
        return
    end
    
    -- 添加到车辆数据
    local newVehicle = {
        id = #vehiclesData + 1,
        model = model,
        name = name,
        price = price,
        category = category,
        maxSpeed = 100,
        acceleration = 8.0,
        seats = 4,
        description = "自定义添加的车辆",
        image = "default.png"
    }
    
    table.insert(vehiclesData, newVehicle)
    
    -- 保存到文件
    SaveResourceFile(GetCurrentResourceName(), "cars.json", json.encode(vehiclesData), -1)
    
    print("^2[车辆系统] 已添加车辆: " .. name .. " (" .. model .. ") - $" .. price .. "^0")
    
    -- 通知所有玩家重新加载车辆数据
    TriggerClientEvent('vehicle:receiveVehicleData', -1, vehiclesData)
end, true)

-- 列出所有车辆命令
RegisterCommand('listcars', function(source, args, rawCommand)
    if source ~= 0 then
        print("^1[车辆系统] 此命令仅限控制台使用^0")
        return
    end
    
    print("^2=== 车辆列表 (" .. #vehiclesData .. " 辆) ===^0")
    for i, vehicle in ipairs(vehiclesData) do
        print(string.format("%d. %s (%s) - $%s [%s]", 
            i, vehicle.name, vehicle.model, vehicle.price, vehicle.category))
    end
end, true)

-- 导出函数
exports('getVehicleData', function(vehicleId)
    for _, vehicle in ipairs(vehiclesData) do
        if vehicle.id == vehicleId then
            return vehicle
        end
    end
    return nil
end)

exports('getAllVehicles', function()
    return vehiclesData
end)

-- 玩家连接时发送车辆数据
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    Citizen.Wait(5000) -- 等待玩家完全连接
    TriggerClientEvent('vehicle:receiveVehicleData', src, vehiclesData)
end)

-- 服务器端购买处理（如果需要服务器验证）
RegisterServerEvent('vehicle:purchaseVehicle')
AddEventHandler('vehicle:purchaseVehicle', function(vehicleId, playerMoney)
    local src = source
    
    -- 查找车辆
    local vehicleData = nil
    for _, vehicle in ipairs(vehiclesData) do
        if vehicle.id == vehicleId then
            vehicleData = vehicle
            break
        end
    end
    
    if not vehicleData then
        TriggerClientEvent('vehicle:purchaseResult', src, false, "Vehicle not found")
        return
    end
    
    -- 这里可以添加服务器端验证逻辑
    -- 例如：检查玩家金钱、记录购买日志等
    
    TriggerClientEvent('vehicle:purchaseResult', src, true, vehicleData)
end)