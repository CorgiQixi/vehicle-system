let vehicles = [];
let selectedVehicle = null;
let playerMoney = 0;
let isUIOpen = false;

// 初始化
document.addEventListener('DOMContentLoaded', function() {
    console.log('Vehicle shop UI loaded');
    
    // 隐藏加载遮罩
    const loadingOverlay = document.getElementById('loadingOverlay');
    const mainContainer = document.getElementById('mainContainer');
    
    // 确保UI元素存在
    if (!mainContainer) {
        console.error('Main container not found!');
        return;
    }
    
    // 设置事件监听器
    setupEventListeners();
    
    // 初始隐藏主容器，显示加载动画
    mainContainer.style.display = 'none';
    
    // 5秒后自动隐藏加载动画（以防万一）
    setTimeout(() => {
        if (loadingOverlay) {
            loadingOverlay.style.opacity = '0';
            setTimeout(() => {
                loadingOverlay.style.display = 'none';
            }, 300);
        }
    }, 5000);
});

// 从服务器加载车辆数据
async function loadVehicles() {
    console.log('Loading vehicles...');
    
    try {
        // 通过NUI从FiveM获取车辆数据
        const response = await fetch(`https://${GetParentResourceName()}/getVehicles`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('Received vehicles data:', data);
        
        if (Array.isArray(data)) {
            vehicles = data;
            displayVehicles();
            showNotification(`已加载 ${data.length} 辆车辆`, 'success');
        } else {
            throw new Error('Invalid data format received');
        }
    } catch (error) {
        console.error('Failed to load vehicles via NUI:', error);
        
        // 尝试直接读取本地cars.json
        try {
            const response = await fetch('./cars.json');
            const data = await response.json();
            
            if (Array.isArray(data)) {
                vehicles = data;
                displayVehicles();
                showNotification('已加载本地车辆数据', 'info');
            }
        } catch (error2) {
            console.error('Failed to load local vehicle data:', error2);
            
            // 使用硬编码的默认数据
            vehicles = [
                {
                    id: 1,
                    model: "adder",
                    name: "Truffade Adder",
                    price: 1000000,
                    category: "Super",
                    maxSpeed: 120,
                    acceleration: 9.5,
                    seats: 2,
                    description: "极速超级跑车，适合追求速度的玩家",
                    image: "adder.png"
                },
                {
                    id: 2,
                    model: "zentorno",
                    name: "Pegassi Zentorno",
                    price: 750000,
                    category: "Super",
                    maxSpeed: 118,
                    acceleration: 9.2,
                    seats: 2,
                    description: "经典超级跑车，平衡性能与价格",
                    image: "zentorno.png"
                }
            ];
            displayVehicles();
            showNotification('使用默认车辆数据', 'warning');
        }
    }
}

// 显示车辆列表
function displayVehicles() {
    const vehicleList = document.getElementById('vehicleList');
    if (!vehicleList) {
        console.error('Vehicle list element not found!');
        return;
    }
    
    vehicleList.innerHTML = '';
    
    if (vehicles.length === 0) {
        vehicleList.innerHTML = '<div class="no-vehicles">暂无车辆数据</div>';
        return;
    }
    
    vehicles.forEach(vehicle => {
        const card = document.createElement('div');
        card.className = 'vehicle-card';
        card.dataset.id = vehicle.id;
        
        // 创建图片URL，如果图片不存在则使用占位符
        const imageUrl = `images/${vehicle.image || 'default.png'}`;
        const fallbackImage = `https://via.placeholder.com/80x60/667eea/ffffff?text=${encodeURIComponent(vehicle.name.substring(0, 10))}`;
        
        card.innerHTML = `
            <img src="${imageUrl}" alt="${vehicle.name}" onerror="this.onerror=null; this.src='${fallbackImage}'">
            <div class="vehicle-info-card">
                <h3>${vehicle.name}</h3>
                <div class="price-tag">$${vehicle.price.toLocaleString()}</div>
                <div class="category">${vehicle.category}</div>
            </div>
        `;
        
        card.addEventListener('click', () => selectVehicle(vehicle.id));
        vehicleList.appendChild(card);
    });
    
    // 默认选择第一辆车
    if (vehicles.length > 0) {
        selectVehicle(vehicles[0].id);
    }
}

// 选择车辆
function selectVehicle(vehicleId) {
    // 移除所有激活状态
    document.querySelectorAll('.vehicle-card').forEach(card => {
        card.classList.remove('active');
    });
    
    // 添加当前激活状态
    const selectedCard = document.querySelector(`.vehicle-card[data-id="${vehicleId}"]`);
    if (selectedCard) {
        selectedCard.classList.add('active');
    }
    
    // 查找车辆数据
    selectedVehicle = vehicles.find(v => v.id == vehicleId);
    if (selectedVehicle) {
        updateVehicleDetails(selectedVehicle);
        updateButtonStates();
    }
}

// 更新车辆详情
function updateVehicleDetails(vehicle) {
    document.getElementById('detailTitle').textContent = vehicle.name;
    document.getElementById('detailCategory').textContent = vehicle.category;
    document.getElementById('detailSpeed').textContent = `${vehicle.maxSpeed} mph`;
    document.getElementById('detailAcceleration').textContent = `${vehicle.acceleration}/10`;
    document.getElementById('detailSeats').textContent = `${vehicle.seats} 个座位`;
    document.getElementById('detailPrice').textContent = `$${vehicle.price.toLocaleString()}`;
    document.getElementById('detailDescription').textContent = vehicle.description;
    
    const imageElement = document.getElementById('detailImage');
    const fallbackImage = `https://via.placeholder.com/600x300/667eea/ffffff?text=${encodeURIComponent(vehicle.name)}`;
    
    // 设置图片，添加错误处理
    imageElement.src = `images/${vehicle.image || 'default.png'}`;
    imageElement.alt = vehicle.name;
    imageElement.onerror = function() {
        this.onerror = null;
        this.src = fallbackImage;
    };
}

// 更新按钮状态
function updateButtonStates() {
    const purchaseBtn = document.getElementById('purchaseBtn');
    const testDriveBtn = document.getElementById('testDriveBtn');
    
    if (!selectedVehicle) {
        purchaseBtn.disabled = true;
        testDriveBtn.disabled = true;
        return;
    }
    
    const canAfford = playerMoney >= selectedVehicle.price;
    purchaseBtn.disabled = !canAfford;
    
    // 更新购买按钮文本
    if (!canAfford) {
        purchaseBtn.innerHTML = `<i class="fas fa-times-circle"></i> 资金不足`;
    } else {
        purchaseBtn.innerHTML = `<i class="fas fa-shopping-cart"></i> 购买`;
    }
}

// 设置事件监听器
function setupEventListeners() {
    console.log('Setting up event listeners');
    
    // 关闭按钮
    const closeBtn = document.getElementById('closeBtn');
    if (closeBtn) {
        closeBtn.addEventListener('click', function() {
            console.log('Close button clicked');
            closeUI();
        });
    } else {
        console.error('Close button not found!');
    }
    
    // 购买按钮
    const purchaseBtn = document.getElementById('purchaseBtn');
    if (purchaseBtn) {
        purchaseBtn.addEventListener('click', function() {
            if (!selectedVehicle || playerMoney < selectedVehicle.price) {
                showNotification('资金不足，无法购买', 'error');
                return;
            }
            
            if (confirm(`确定要购买 ${selectedVehicle.name} 吗？\n价格: $${selectedVehicle.price.toLocaleString()}`)) {
                console.log('Purchasing vehicle:', selectedVehicle.id);
                
                fetch(`https://${GetParentResourceName()}/purchase`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: JSON.stringify({
                        vehicleId: selectedVehicle.id
                    })
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        showNotification(`成功购买 ${selectedVehicle.name}！`, 'success');
                        playerMoney = data.newBalance || playerMoney - selectedVehicle.price;
                        document.getElementById('playerMoney').textContent = `$${playerMoney.toLocaleString()}`;
                        updateButtonStates();
                    } else {
                        showNotification(data.message || '购买失败', 'error');
                    }
                })
                .catch(error => {
                    console.error('Purchase request failed:', error);
                    showNotification('购买请求失败', 'error');
                });
            }
        });
    }
    
    // 试驾按钮
    const testDriveBtn = document.getElementById('testDriveBtn');
    if (testDriveBtn) {
        testDriveBtn.addEventListener('click', function() {
            if (!selectedVehicle) return;
            
            console.log('Test drive requested for:', selectedVehicle.model);
            
            fetch(`https://${GetParentResourceName()}/testDrive`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({
                    model: selectedVehicle.model
                })
            });
        });
    }
    
    // ESC键监听
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape' && isUIOpen) {
            console.log('ESC pressed, closing UI');
            closeUI();
        }
    });
}

// 关闭UI
function closeUI() {
    console.log('Closing UI');
    
    const mainContainer = document.getElementById('mainContainer');
    if (mainContainer) {
        mainContainer.style.display = 'none';
    }
    
    isUIOpen = false;
    
    // 通知游戏客户端关闭UI
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
}

// 显示通知
function showNotification(message, type = 'info') {
    console.log(`Notification [${type}]: ${message}`);
    
    const notification = document.getElementById('notification');
    const text = document.getElementById('notificationText');
    
    if (!notification || !text) {
        console.error('Notification elements not found!');
        return;
    }
    
    text.textContent = message;
    notification.className = 'notification';
    
    // 根据类型设置颜色
    switch(type) {
        case 'error':
            notification.style.background = '#dc3545';
            break;
        case 'success':
            notification.style.background = '#28a745';
            break;
        case 'warning':
            notification.style.background = '#ffc107';
            break;
        default:
            notification.style.background = '#007bff';
    }
    
    notification.classList.add('show');
    
    // 3秒后隐藏
    setTimeout(() => {
        notification.classList.remove('show');
    }, 3000);
}

// NUI消息处理
window.addEventListener('message', function(event) {
    const data = event.data;
    console.log('Received message from game:', data);
    
    switch(data.type) {
        case 'OPEN_SHOP':
            console.log('Opening shop UI');
            
            const loadingOverlay = document.getElementById('loadingOverlay');
            const mainContainer = document.getElementById('mainContainer');
            
            // 隐藏加载动画
            if (loadingOverlay) {
                loadingOverlay.style.opacity = '0';
                setTimeout(() => {
                    loadingOverlay.style.display = 'none';
                }, 300);
            }
            
            // 显示主容器
            if (mainContainer) {
                mainContainer.style.display = 'block';
                mainContainer.style.visibility = 'visible';
                mainContainer.style.opacity = '1';
            }
            
            playerMoney = data.playerMoney || 0;
            document.getElementById('playerMoney').textContent = `$${playerMoney.toLocaleString()}`;
            
            isUIOpen = true;
            loadVehicles();
            break;
            
        case 'CLOSE_SHOP':
            console.log('Closing shop UI');
            closeUI();
            break;
            
        case 'SHOW_NOTIFICATION':
            showNotification(data.message, data.notificationType || 'info');
            break;
            
        case 'UPDATE_MONEY':
            playerMoney = data.amount || 0;
            document.getElementById('playerMoney').textContent = `$${playerMoney.toLocaleString()}`;
            updateButtonStates();
            break;
            
        case 'RECEIVE_VEHICLES':
            vehicles = data.vehicles || [];
            displayVehicles();
            break;
    }
});

// 调试：测试UI是否正常工作
window.testUI = function() {
    const mainContainer = document.getElementById('mainContainer');
    if (mainContainer) {
        mainContainer.style.display = 'block';
        isUIOpen = true;
        loadVehicles();
        showNotification('UI测试成功', 'success');
    }
};

console.log('Vehicle shop script loaded successfully');