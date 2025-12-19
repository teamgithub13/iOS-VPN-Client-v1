# VPN Protocol Implementations

Этот каталог содержит обертки для различных VPN протоколов.

## Структура

- `WireGuardTunnel.swift` - Реализация WireGuard протокола
- `V2RayTunnel.swift` - Реализация V2Ray протоколов (VLESS/VMess)
- `ShadowsocksTunnel.swift` - Реализация Shadowsocks протокола

## Архитектура

Каждый класс туннеля следует единому интерфейсу:

```swift
class ProtocolTunnel {
    init(config: VPNConfiguration)
    func start(packetFlow: NEPacketTunnelFlow, completionHandler: @escaping (Error?) -> Void)
    func stop()
}
```

## Текущее состояние

Все обертки содержат базовую структуру и готовы к интеграции реальных библиотек. 

### WireGuard
- ✅ Базовая структура
- ✅ Обработка конфигурации
- ⏳ Требует интеграции WireGuardKit

### V2Ray (VLESS/VMess)
- ✅ Базовая структура
- ✅ Генерация JSON конфигурации
- ⏳ Требует интеграции v2ray-core

### Shadowsocks
- ✅ Базовая структура
- ✅ Генерация ключей шифрования
- ⏳ Требует интеграции shadowsocks-libev

## Интеграция библиотек

См. `LIBRARY_INTEGRATION.md` в корне проекта для подробных инструкций.

## Использование

Обертки используются автоматически через `PacketTunnelProvider`:

```swift
switch config.protocolType {
case .wireguard:
    let tunnel = WireGuardTunnel(config: config)
    tunnel.start(packetFlow: packetFlow, completionHandler: completionHandler)
case .vless, .vmess:
    let tunnel = V2RayTunnel(config: config)
    tunnel.start(packetFlow: packetFlow, completionHandler: completionHandler)
case .shadowsocks, .shadowsocksR:
    let tunnel = ShadowsocksTunnel(config: config)
    tunnel.start(packetFlow: packetFlow, completionHandler: completionHandler)
}
```

## Расширение

Для добавления нового протокола:

1. Создайте новый класс туннеля по образцу существующих
2. Реализуйте методы `start()` и `stop()`
3. Добавьте обработку в `PacketTunnelProvider.startTunnel()`
4. Обновите `VPNProtocolType` enum

