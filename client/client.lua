local display = false
local ownedVehicles = {}
local playerMoney = 50000 -- 默认金额
local vehiclesData = {} -- 存储从服务器获取的车辆数据

-- 调试模式
local debugMode = true

-- 显示调试信息
function DebugPrint(msg)
    if debugMode then
        print("[Vehicle System Debug] " .. msg)
    end
end

-- 初始化
Citizen.CreateThread(function()
    -- 加载已拥有的车辆（从本地存储）
    LoadOwnedVehicles()
    
    -- 从服务器获取车辆数据
    TriggerServerEvent('vehicle:requestVehicleData')
    
    -- 显示启动提示
    Citizen.Wait(3000) -- 等待3秒让玩家进入游戏
    ShowNotification("Press ~y~F4~s~ to open Vehicle Shop, Press ~y~K~s~ for Mechanic", 1)
    DebugPrint("Vehicle system initialized")
    
    -- 监听按键
    while true do
        Citizen.Wait(0)
        
        -- 检查按键状态
        CheckKeyPresses()
        
        -- 调试：添加金钱（开发用）
        if IsControlJustReleased(0, 214) then -- Delete键添加$10000
            playerMoney = playerMoney + 10000
            ShowNotification("Added $10000. Current money: $" .. playerMoney, 2)
            DebugPrint("Money added: $10000, Total: $" .. playerMoney)
        end
    end
end)

-- 检查按键按下
function CheckKeyPresses()
    -- F4键打开车辆商店 (166 = F4键)
    if IsControlJustReleased(0, 166) then
        DebugPrint("F4 key pressed")
        OpenVehicleShop()
    end
    
    -- 备用按键：F5 (167) 如果F4不工作
    if IsControlJustReleased(0, 167) then
        DebugPrint("F5 key pressed (alternative)")
        OpenVehicleShop()
    end
    
    -- ESC键关闭UI
    if display and IsControlJustReleased(0, 322) then -- ESC键
        DebugPrint("ESC key pressed, closing shop")
        CloseVehicleShop()
    end
end

-- 打开车辆商店
function OpenVehicleShop()
    if display then 
        DebugPrint("Shop already open, closing...")
        CloseVehicleShop()
        return 
    end
    
    DebugPrint("Opening vehicle shop...")
    
    -- 设置NUI焦点和显示状态
    display = true
    SetNuiFocus(true, true)
    
    -- 发送打开消息给UI
    SendNUIMessage({
        type = 'OPEN_SHOP',
        playerMoney = playerMoney,
        vehicles = vehiclesData -- 直接发送车辆数据
    })
    
    DebugPrint("Vehicle shop opened successfully")
    ShowNotification("Vehicle Shop Opened", 1)
end

-- 关闭UI
function CloseVehicleShop()
    DebugPrint("Closing vehicle shop...")
    display = false
    SetNuiFocus(false, false)
    SendNUIMessage({type = 'CLOSE_SHOP'})
    ShowNotification("Vehicle Shop Closed", 1)
end

-- 加载已拥有车辆
function LoadOwnedVehicles()
    local saved = GetResourceKvpString('owned_vehicles')
    if saved then
        ownedVehicles = json.decode(saved)
        DebugPrint("Loaded " .. #ownedVehicles .. " owned vehicles")
    else
        ownedVehicles = {}
        DebugPrint("No saved vehicles found")
    end
end

-- 保存已拥有车辆
function SaveOwnedVehicles()
    SetResourceKvp('owned_vehicles', json.encode(ownedVehicles))
    DebugPrint("Saved " .. #ownedVehicles .. " vehicles")
end

-- 生成车牌号
function GeneratePlate()
    local plate = ""
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    for i = 1, 8 do
        local rand = math.random(1, #chars)
        plate = plate .. chars:sub(rand, rand)
    end
    
    DebugPrint("Generated plate: " .. plate)
    return plate
end

-- NUI回调（所有NUI回调都在客户端处理）
RegisterNUICallback('getVehicles', function(data, cb)
    DebugPrint("NUI getVehicles callback received")
    cb(vehiclesData)
end)

RegisterNUICallback('close', function(data, cb)
    DebugPrint("NUI close callback received")
    CloseVehicleShop()
    cb('ok')
end)

RegisterNUICallback('purchase', function(data, cb)
    DebugPrint("Purchase request for vehicle ID: " .. (data.vehicleId or "unknown"))
    
    -- 从本地数据查找车辆
    local vehicleData = FindVehicleById(data.vehicleId)
    if vehicleData then
        PurchaseVehicle(vehicleData)
        cb({success = true})
    else
        ShowNotification("Vehicle not found", 3)
        cb({success = false, message = "Vehicle not found"})
    end
end)

RegisterNUICallback('testDrive', function(data, cb)
    DebugPrint("Test drive request for model: " .. (data.model or "unknown"))
    StartTestDrive(data.model)
    cb('ok')
end)

-- 从本地查找车辆
function FindVehicleById(vehicleId)
    for _, vehicle in ipairs(vehiclesData) do
        if tostring(vehicle.id) == tostring(vehicleId) then
            return vehicle
        end
    end
    
    -- 如果没有在vehiclesData中找到，尝试重新从服务器获取
    DebugPrint("Vehicle not found in cache, requesting from server...")
    return nil
end

-- 接收车辆数据的事件
RegisterNetEvent('vehicle:receiveVehicleData')
AddEventHandler('vehicle:receiveVehicleData', function(data)
    vehiclesData = data or {}
    DebugPrint("Received " .. #vehiclesData .. " vehicles from server")
end)

-- 显示通知
function ShowNotification(msg, type)
    -- type 1: 黄色, 2: 绿色, 3: 红色
    
    -- 使用游戏内置通知系统
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentString(msg)
    
    if type == 2 then
        -- 绿色通知
        ThefeedSetNextPostBackgroundColor(2) -- 绿色背景
    elseif type == 3 then
        -- 红色通知
        ThefeedSetNextPostBackgroundColor(6) -- 红色背景
    end
    
    EndTextCommandThefeedPostTicker(false, true)
end

-- 购买车辆
function PurchaseVehicle(vehicleData)
    if not vehicleData then
        ShowNotification("Invalid vehicle data", 3)
        return
    end
    
    if playerMoney < vehicleData.price then
        ShowNotification("Insufficient funds", 3)
        return
    end
    
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        ShowNotification("Please exit your current vehicle first", 3)
        return
    end
    
    -- 扣款
    playerMoney = playerMoney - vehicleData.price
    DebugPrint("Purchased " .. vehicleData.name .. " for $" .. vehicleData.price .. ", remaining: $" .. playerMoney)
    
    -- 生成车辆
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    -- 请求模型
    local modelHash = GetHashKey(vehicleData.model)
    RequestModel(modelHash)
    
    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    
    if not HasModelLoaded(modelHash) then
        ShowNotification("Failed to load vehicle model: " .. vehicleData.model, 3)
        playerMoney = playerMoney + vehicleData.price -- 退款
        return
    end
    
    -- 在玩家前方生成车辆
    local forward = GetEntityForwardVector(playerPed)
    local spawnCoords = vector3(
        coords.x + forward.x * 5,
        coords.y + forward.y * 5,
        coords.z
    )
    
    -- 检查生成点是否安全
    local found, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z, false)
    if found then
        spawnCoords = vector3(spawnCoords.x, spawnCoords.y, groundZ)
    end
    
    local vehicle = CreateVehicle(
        modelHash,
        spawnCoords.x,
        spawnCoords.y,
        spawnCoords.z + 0.5,
        heading,
        true,
        false
    )
    
    if not DoesEntityExist(vehicle) then
        ShowNotification("Failed to create vehicle", 3)
        playerMoney = playerMoney + vehicleData.price -- 退款
        return
    end
    
    -- 设置车牌
    local plate = GeneratePlate()
    SetVehicleNumberPlateText(vehicle, plate)
    
    -- 设置车辆属性
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)
    
    -- 添加玩家到车辆
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
    
    -- 保存到已拥有车辆列表
    local vehicleProps = {
        id = vehicleData.id,
        model = vehicleData.model,
        name = vehicleData.name,
        plate = plate,
        price = vehicleData.price,
        timestamp = os.time()
    }
    
    table.insert(ownedVehicles, vehicleProps)
    SaveOwnedVehicles()
    
    -- 更新UI金额
    SendNUIMessage({
        type = 'UPDATE_MONEY',
        amount = playerMoney
    })
    
    ShowNotification('Purchased ' .. vehicleData.name .. '! Plate: ' .. plate, 2)
    
    CloseVehicleShop()
end

-- 试驾
function StartTestDrive(model)
    if not model then
        ShowNotification("Invalid model", 3)
        return
    end
    
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        ShowNotification("Please exit your current vehicle first", 3)
        return
    end
    
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    
    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 100 do
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    
    if not HasModelLoaded(modelHash) then
        ShowNotification("Failed to load vehicle model", 3)
        return
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    -- 在玩家前方生成车辆
    local forward = GetEntityForwardVector(playerPed)
    local spawnCoords = vector3(
        coords.x + forward.x * 5,
        coords.y + forward.y * 5,
        coords.z
    )
    
    local found, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z, false)
    if found then
        spawnCoords = vector3(spawnCoords.x, spawnCoords.y, groundZ)
    end
    
    local vehicle = CreateVehicle(
        modelHash,
        spawnCoords.x,
        spawnCoords.y,
        spawnCoords.z + 0.5,
        heading,
        true,
        false
    )
    
    if not DoesEntityExist(vehicle) then
        ShowNotification("Failed to create test drive vehicle", 3)
        return
    end
    
    SetVehicleNumberPlateText(vehicle, "TESTDRIVE")
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)
    
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
    
    ShowNotification('Test drive started. Vehicle will disappear in 5 minutes.', 1)
    
    -- 5分钟后删除试驾车辆
    Citizen.CreateThread(function()
        Citizen.Wait(300000) -- 5分钟
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
            ShowNotification('Test drive ended.', 1)
        end
    end)
end

-- 网络事件
RegisterNetEvent('vehicle:updateMoney')
AddEventHandler('vehicle:updateMoney', function(amount)
    playerMoney = amount
    SendNUIMessage({
        type = 'UPDATE_MONEY',
        amount = playerMoney
    })
end)

-- 导出函数
exports('getOwnedVehicles', function()
    return ownedVehicles
end)

exports('getPlayerMoney', function()
    return playerMoney
end)

exports('addMoney', function(amount)
    playerMoney = playerMoney + amount
    TriggerEvent('vehicle:updateMoney', playerMoney)
    return playerMoney
end)

-- 命令：打开车辆商店
RegisterCommand('vehicleshop', function()
    OpenVehicleShop()
end, false)

-- 命令：查看已拥有车辆
RegisterCommand('myvehicles', function()
    if #ownedVehicles == 0 then
        ShowNotification("You don't own any vehicles", 1)
        return
    end
    
    ShowNotification("=== OWNED VEHICLES ===", 1)
    
    for i, vehicle in ipairs(ownedVehicles) do
        Citizen.Wait(100)
        ShowNotification(vehicle.plate .. ": " .. vehicle.name .. " ($" .. vehicle.price .. ")", 1)
    end
end, false)

-- 命令：生成已拥有车辆
RegisterCommand('spawnvehicle', function(source, args)
    if #args < 1 then
        ShowNotification("Usage: /spawnvehicle [PLATE] - Spawn your owned vehicle", 3)
        return
    end
    
    local plate = args[1]:upper()
    local vehicleData = nil
    
    for _, vehicle in ipairs(ownedVehicles) do
        if vehicle.plate == plate then
            vehicleData = vehicle
            break
        end
    end
    
    if not vehicleData then
        ShowNotification("Vehicle with plate " .. plate .. " not found", 3)
        return
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    local modelHash = GetHashKey(vehicleData.model)
    RequestModel(modelHash)
    
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(10)
    end
    
    local forward = GetEntityForwardVector(playerPed)
    local spawnCoords = vector3(
        coords.x + forward.x * 5,
        coords.y + forward.y * 5,
        coords.z
    )
    
    local found, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z, false)
    if found then
        spawnCoords = vector3(spawnCoords.x, spawnCoords.y, groundZ)
    end
    
    local vehicle = CreateVehicle(
        modelHash,
        spawnCoords.x,
        spawnCoords.y,
        spawnCoords.z + 0.5,
        heading,
        true,
        false
    )
    
    SetVehicleNumberPlateText(vehicle, vehicleData.plate)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)
    
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
    
    ShowNotification("Spawned: " .. vehicleData.name, 2)
end, false)

-- 资源停止时关闭UI
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName and display then
        SetNuiFocus(false, false)
        SendNUIMessage({type = 'CLOSE_SHOP'})
    end
end)

-- 添加一个简单的测试命令
RegisterCommand('testf4', function()
    print("Testing F4 key...")
    print("F4 key code: 166")
    print("Alternative F5 key code: 167")
    print("Current display state: " .. tostring(display))
    print("Player money: $" .. playerMoney)
    print("Vehicles in cache: " .. #vehiclesData)
    
    -- 测试打开商店
    OpenVehicleShop()
end, false)