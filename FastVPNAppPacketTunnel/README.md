# Network Extension для FastVPN

Этот Network Extension реализует PacketTunnelProvider для работы VPN протоколов.

## Поддерживаемые протоколы

- **WireGuard** - через wireguard-go (требует интеграции)
- **VLESS** - через v2ray-core (требует интеграции)
- **VMess** - через v2ray-core (требует интеграции)
- **Shadowsocks** - через shadowsocks-libev (требует интеграции)
- **ShadowsocksR** - через shadowsocks-libev (требует интеграции)

## Архитектура

### PacketTunnelProvider.swift

Основной класс extension, который:
1. Получает конфигурацию из App Group UserDefaults
2. Определяет тип протокола
3. Запускает соответствующий туннель
4. Управляет сетевыми настройками

### Передача конфигурации

Конфигурация передается из основного приложения в extension через:
1. **App Group UserDefaults** - основная конфигурация
2. **NETunnelProviderProtocol.providerConfiguration** - дополнительные параметры

## Следующие шаги для интеграции библиотек

### WireGuard

1. Добавить wireguard-go или WireGuardKit
2. Реализовать метод `startWireGuardTunnel` с использованием библиотеки
3. Настроить TUN интерфейс для работы с WireGuard

### V2Ray (VLESS/VMess)

1. Добавить v2ray-core
2. Реализовать методы `startV2RayTunnel` для обоих протоколов
3. Настроить проксирование трафика через V2Ray

### Shadowsocks

1. Добавить shadowsocks-libev или аналогичную библиотеку
2. Реализовать метод `startShadowsocksTunnel`
3. Настроить SOCKS5 проксирование

## Отладка

Для отладки extension:
1. Используйте `os_log` для логирования
2. Проверяйте логи в Console.app с фильтром по bundle identifier extension
3. Используйте Network Link Conditioner для тестирования различных сетевых условий

