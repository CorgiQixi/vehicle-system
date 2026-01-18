local mechanicMenu = false
local mechanicCalled = false
local mechanicCooldown = 0
local mechanicData = nil
local showMechanicMenu = false
local selectedServiceIndex = 1

-- 技工服务选项（使用ASCII字符避免乱码）
local mechanicServices = {
    {label = "Repair Vehicle", price = 500, type = "repair"},
    {label = "Clean Vehicle", price = 100, type = "clean"},
    {label = "Paint Vehicle", price = 1000, type = "paint"},
    {label = "Upgrade Engine", price = 5000, type = "engine"},
    {label = "Upgrade Brakes", price = 3000, type = "brakes"},
    {label = "Call Tow Truck", price = 800, type = "tow"},
    {label = "Flip Vehicle", price = 200, type = "flip"}
}

-- 监听K键打开技工菜单
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- K键打开技工菜单 (311是K键)
        if IsControlJustReleased(0, 311) then
            ToggleMechanicMenu()
        end
        
        -- ESC键关闭菜单
        if showMechanicMenu and IsControlJustReleased(0, 322) then
            showMechanicMenu = false
        end
        
        -- 菜单内导航
        if showMechanicMenu then
            -- 上下键选择
            if IsControlJustReleased(0, 172) then -- 上箭头
                selectedServiceIndex = selectedServiceIndex - 1
                if selectedServiceIndex < 1 then
                    selectedServiceIndex = #mechanicServices
                end
                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
            elseif IsControlJustReleased(0, 173) then -- 下箭头
                selectedServiceIndex = selectedServiceIndex + 1
                if selectedServiceIndex > #mechanicServices then
                    selectedServiceIndex = 1
                end
                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
            end
            
            -- 回车键选择
            if IsControlJustReleased(0, 176) then -- 回车键
                RequestMechanicService(mechanicServices[selectedServiceIndex])
                showMechanicMenu = false
            end
            
            -- 绘制菜单
            DrawMechanicMenu()
        end
    end
end)

-- 切换技工菜单
function ToggleMechanicMenu()
    if showMechanicMenu then
        showMechanicMenu = false
        return
    end
    
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    -- 重置选择
    selectedServiceIndex = 1
    showMechanicMenu = true
    
    ShowNotification("Use UP/DOWN to select, ENTER to confirm, ESC to close", 1)
end

-- 绘制技工菜单
function DrawMechanicMenu()
    -- 绘制背景
    DrawRect(0.5, 0.5, 0.3, 0.4, 0, 0, 0, 200)
    
    -- 绘制标题
    SetTextFont(4)  -- 使用默认字体
    SetTextProportional(1)
    SetTextScale(0.5, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString("=== MECHANIC SERVICES ===")
    DrawText(0.4, 0.35)
    
    -- 绘制服务列表
    for i, service in ipairs(mechanicServices) do
        local yPos = 0.4 + (i * 0.04)
        local color = {255, 255, 255, 255}
        
        if i == selectedServiceIndex then
            color = {255, 200, 0, 255}
        end
        
        SetTextFont(4)
        SetTextProportional(1)
        SetTextScale(0.35, 0.35)
        SetTextColour(color[1], color[2], color[3], color[4])
        SetTextEntry("STRING")
        
        local text = string.format("%s - $%d", service.label, service.price)
        if i == selectedServiceIndex then
            text = "> " .. text .. " <"
        end
        
        AddTextComponentString(text)
        DrawText(0.4, yPos)
    end
    
    -- 绘制说明
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(0.3, 0.3)
    SetTextColour(200, 200, 200, 255)
    SetTextEntry("STRING")
    AddTextComponentString("UP/DOWN: Select | ENTER: Confirm | ESC: Close")
    DrawText(0.4, 0.65)
end

-- 显示通知（使用游戏内置通知系统，支持中文）
function ShowNotification(msg, type)
    -- type 1: 黄色, 2: 绿色, 3: 红色
    
    -- 使用游戏内置通知系统（支持中文）
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    
    if type == 2 then
        -- 绿色通知
        SetNotificationMessage("CHAR_LS_CUSTOMS", "CHAR_LS_CUSTOMS", true, 1, "Mechanic Service", "Service Completed")
    elseif type == 3 then
        -- 红色通知
        SetNotificationMessage("CHAR_LS_CUSTOMS", "CHAR_LS_CUSTOMS", true, 4, "Mechanic Service", "Error")
    else
        -- 黄色通知
        SetNotificationMessage("CHAR_LS_CUSTOMS", "CHAR_LS_CUSTOMS", true, 2, "Mechanic Service", "Info")
    end
    
    DrawNotification(false, false)
end

-- 剩余的函数保持不变...