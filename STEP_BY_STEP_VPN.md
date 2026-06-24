# Пошаговая инструкция: Как заставить VPN работать

## 📋 Текущее состояние

✅ **Готово:**
- Парсинг всех протоколов (VLESS, VMess, Shadowsocks, WireGuard)
- UI для управления VPN
- Архитектура подключения через NetworkExtension
- Базовая структура PacketTunnelProvider

⏳ **Нужно сделать:**
- Добавить файлы Extension в Xcode проект
- Интегрировать библиотеки для реальной работы протоколов

## 🎯 Шаг 1: Добавить файлы Extension в Xcode

Файлы находятся в папке `FastVPNAppPacketTunnel/`, их нужно добавить в Extension target:

### В Xcode:

1. **Правой кнопкой на target `FastVPNAppPacketTunnel`** в навигаторе проекта
2. **"Add Files to 'FastVPNAppPacketTunnel'..."**
3. **Перейдите в папку `FastVPNAppPacketTunnel/`** (в корне проекта)
4. **Выберите:**
   - `PacketTunnelProvider.swift`
   - Папку `Models/` (VPNConfiguration.swift, VPNProtocolType.swift)
   - Папку `Protocols/` (WireGuardTunnel.swift, V2RayTunnel.swift, ShadowsocksTunnel.swift)
5. **Настройки:**
   - ❌ "Copy items if needed" - НЕ отмечено
   - ✅ "Create groups" - отмечено
   - ✅ Target: только `FastVPNAppPacketTunnel` (НЕ основной!)
6. **Нажмите "Add"**

### Проверка:

После добавления в навигаторе должно быть:
```
FastVPNAppPacketTunnel
├── PacketTunnelProvider.swift
├── Models/
│   ├── VPNConfiguration.swift
│   └── VPNProtocolType.swift
└── Protocols/
    ├── WireGuardTunnel.swift
    ├── V2RayTunnel.swift
    └── ShadowsocksTunnel.swift
```

## 🎯 Шаг 2: Настроить App Groups

### В Xcode:

1. **Target `FastVPNApp`** → Signing & Capabilities
   - + Capability → **App Groups**
   - Добавьте: `group.com.asdf.FastVPNApp`

2. **Target `FastVPNAppPacketTunnel`** → Signing & Capabilities
   - + Capability → **App Groups**
   - Добавьте **ту же** группу: `group.com.asdf.FastVPNApp`
   - + Capability → **Personal VPN**
   - Убедитесь, что "Packet Tunnel" выбран

## 🎯 Шаг 3: Интегрировать WireGuard (Начните с этого!)

WireGuard - самый простой протокол для начала.

### 3.1 Добавить WireGuardKit

1. **В Xcode:** File → Add Packages...
2. **URL:** `https://github.com/WireGuard/wireguard-apple`
3. **Выберите:** `WireGuardKit` (последняя версия)
4. **Добавьте в targets:**
   - ✅ `FastVPNApp`
   - ✅ `FastVPNAppPacketTunnel`

### 3.2 Обновить WireGuardTunnel.swift

После добавления WireGuardKit, обновите `WireGuardTunnel.swift`:

```swift
import WireGuardKit

class WireGuardTunnel {
    private var adapter: WireGuardAdapter?
    
    func start(packetFlow: NEPacketTunnelFlow, completionHandler: @escaping (Error?) -> Void) {
        guard let privateKey = config.privateKey,
              let publicKey = config.publicKey,
              let endpoint = config.endpoint else {
            completionHandler(NSError(...))
            return
        }
        
        // Создаем конфигурацию WireGuard
        var wgConfig = """
        [Interface]
        PrivateKey = \(privateKey)
        Address = \(config.allowedIPs ?? "10.0.0.2/32")
        DNS = \(config.dns ?? "8.8.8.8")
        
        [Peer]
        PublicKey = \(publicKey)
        Endpoint = \(endpoint):\(config.port)
        AllowedIPs = \(config.allowedIPs ?? "0.0.0.0/0")
        """
        
        if let presharedKey = config.presharedKey {
            wgConfig += "\nPresharedKey = \(presharedKey)"
        }
        
        // Создаем адаптер
        adapter = WireGuardAdapter(with: packetFlow)
        
        // Запускаем туннель
        adapter?.start(tunnelConfiguration: wgConfig) { error in
            completionHandler(error)
        }
    }
    
    func stop() {
        adapter?.stop { }
        adapter = nil
    }
}
```

## 🎯 Шаг 4: Протестировать

1. **Подключите iPhone/iPad**
2. **Запустите приложение**
3. **Добавьте WireGuard конфигурацию:**
   - Формат: `wireguard://base64(config)` или конфигурационный файл
4. **Нажмите кнопку подключения**
5. **Проверьте, что VPN подключается**

## 📝 Что дальше после WireGuard

### Shadowsocks:
- Найти готовую Swift библиотеку
- Или использовать shadowsocks-libev
- Обновить ShadowsocksTunnel.swift

### V2Ray (VLESS/VMess):
- Изучить v2ray-core
- Найти готовую обертку или скомпилировать
- Обновить V2RayTunnel.swift

## ✅ Чеклист

- [ ] Файлы Extension добавлены в Xcode проект
- [ ] App Groups настроен в обоих targets
- [ ] Personal VPN настроен в Extension target
- [ ] WireGuardKit добавлен через SPM
- [ ] WireGuardTunnel.swift обновлен
- [ ] Проект компилируется
- [ ] Приложение запускается на устройстве
- [ ] WireGuard подключение работает

## 🐛 Решение проблем

### "Cannot find type 'VPNConfiguration'"
- Убедитесь, что Models добавлены в Extension target

### "Cannot find type 'WireGuardTunnel'"
- Убедитесь, что Protocols добавлены в Extension target

### "App Groups не работает"
- Проверьте, что группа одинаковая в обоих targets
- Проверьте, что App Groups включен в App IDs в Developer Portal

### "VPN не подключается"
- Проверьте логи в Console.app
- Убедитесь, что конфигурация правильная
- Проверьте, что WireGuardKit правильно интегрирован

## 🚀 Быстрый старт

**Самый быстрый способ начать:**

1. Добавьте файлы Extension в Xcode (Шаг 1)
2. Настройте App Groups (Шаг 2)
3. Добавьте WireGuardKit (Шаг 3.1)
4. Обновите WireGuardTunnel.swift (Шаг 3.2)
5. Протестируйте (Шаг 4)

После этого WireGuard будет работать! 🎉

