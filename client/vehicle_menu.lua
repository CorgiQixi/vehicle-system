-- 这个文件用于处理车辆相关的其他功能
local vehicleBlips = {}

-- 为已拥有车辆添加地图标记
function AddVehicleBlip(vehicleProps)
    local model = vehicleProps.model
    local plate = vehicleProps.plate
    
    -- 获取车辆哈希
    local hash = GetHashKey(model)
    
    -- 创建标记
    local blip = AddBlipForEntity(vehicle)
    SetBlipSprite(blip, 225) -- 车辆图标
    SetBlipColour(blip, 3)   -- 绿色
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("我的车辆: " .. vehicleProps.name)
    EndTextCommandSetBlipName(blip)
    
    -- 保存标记
    vehicleBlips[plate] = blip
end

-- 移除车辆标记
function RemoveVehicleBlip(plate)
    if vehicleBlips[plate] then
        RemoveBlip(vehicleBlips[plate])
        vehicleBlips[plate] = nil
    end
end

-- 跟踪最近购买的车辆
local lastPurchasedVehicle = nil

-- 网络事件：接收车辆数据
RegisterNetEvent('vehicle:receiveVehicleData')
AddEventHandler('vehicle:receiveVehicleData', function(data)
    print("^2[客户端] 已接收车辆数据，共 " .. #data .. " 辆车辆^0")
    
    -- 这里可以处理接收到的车辆数据
    -- 例如更新UI或进行其他操作
end)

-- 车辆保护系统（防止车辆消失）
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000) -- 每30秒检查一次
        
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle ~= 0 then
            local plate = GetVehicleNumberPlateText(vehicle)
            
            -- 检查是否是自己购买的车辆
            local ownedVehicles = exports['vehicle-system']:getOwnedVehicles()
            local isOwned = false
            
            for _, ownedVehicle in ipairs(ownedVehicles) do
                if ownedVehicle.plate == plate then
                    isOwned = true
                    break
                end
            end
            
            -- 如果是自己的车辆，设置一些保护属性
            if isOwned then
                SetVehicleHasBeenOwnedByPlayer(vehicle, true)
                SetEntityAsMissionEntity(vehicle, true, true)
                SetVehicleIsStolen(vehicle, false)
                SetVehicleIsWanted(vehicle, false)
            end
        end
    end
end)

-- 车辆锁定系统
local vehicleLocked = false

RegisterCommand('lock', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        -- 不在车内，尝试获取最近的车辆
        vehicle = GetClosestVehicle(GetEntityCoords(playerPed), 5.0, 0, 70)
    end
    
    if vehicle ~= 0 then
        local plate = GetVehicleNumberPlateText(vehicle)
        local ownedVehicles = exports['vehicle-system']:getOwnedVehicles()
        local isOwned = false
        
        for _, ownedVehicle in ipairs(ownedVehicles) do
            if ownedVehicle.plate == plate then
                isOwned = true
                break
            end
        end
        
        if isOwned then
            vehicleLocked = not vehicleLocked
            
            if vehicleLocked then
                SetVehicleDoorsLocked(vehicle, 2) -- 锁定
                ShowNotification("车辆已锁定", 2)
            else
                SetVehicleDoorsLocked(vehicle, 1) -- 解锁
                ShowNotification("车辆已解锁", 2)
            end
            
            -- 播放锁定音效
            PlaySoundFrontend(-1, "REMOTE_PLAYER_CASH_COUNTER_COMPLETE", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
        else
            ShowNotification("这不是你的车辆", 1)
        end
    else
        ShowNotification("附近没有车辆", 1)
    end
end, false)

-- 显示通知函数
function ShowNotification(msg, type)
    local color = {255, 255, 0}
    if type == 1 then
        color = {255, 0, 0}
    elseif type == 2 then
        color = {0, 255, 0}
    end
    
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(true, true)
end