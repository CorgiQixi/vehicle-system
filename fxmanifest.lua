fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Native FiveM Vehicle Purchase and Mechanic System'
version '1.0.0'

-- 客户端脚本
client_scripts {
    'client/client.lua',
    'client/mechanic.lua',
    'client/vehicle_menu.lua'
}

-- 服务器脚本
server_scripts {
    'server/server.lua'
}

-- UI文件
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'cars.json'
    -- 移除了无效的图片路径
}

-- 如果需要图片，确保它们存在并正确引用