# PROD REVERT NOTES — откат перед релизом

## Что переименовано для тестового бандла `com.gooseberry.colanderTest`

Все изменения — это переименование `com.gooseberry.colander` → `com.gooseberry.colanderTest`.
Для прода нужно вернуть обратно `com.gooseberry.colanderTest` → `com.gooseberry.colander`.

### 1. project.pbxproj (4 строки)
- `PRODUCT_BUNDLE_IDENTIFIER = com.gooseberry.colanderTest;` (FastVPNApp, Debug + Release) → `com.gooseberry.colander`
- `PRODUCT_BUNDLE_IDENTIFIER = com.gooseberry.colanderTest.tunnel;` (FastVPNAppPacketTunnel, Debug + Release) → `com.gooseberry.colander.tunnel`

### 2. Entitlements (4 файла)
- `FastVPNApp/FastVPNApp.entitlements` — `group.com.gooseberry.colanderTest` → `group.com.gooseberry.colander`
- `FastVPNAppPacketTunnel/FastVPNAppPacketTunnel.entitlements` — то же
- `FastVPNApp/NetworkExtension/FastVPNAppPacketTunnel.entitlements` — то же
- `FastVPNApp.entitlements` (корень) — НЕ трогали (там другой bundle `com.asdf.FastVPNApp`)

### 3. Swift-код (3 файла)
- `FastVPNApp/Service/Services/VPNConnectionService.swift:23-24`
  - `appGroupIdentifier` → `group.com.gooseberry.colander`
  - `tunnelProviderBundleIdentifier` → `com.gooseberry.colander.tunnel`
- `FastVPNAppPacketTunnel/PacketTunnelProvider.swift:12` — `group.com.gooseberry.colander`
- `FastVPNAppPacketTunnel/Protocols/V2RayTunnel.swift:9` — `group.com.gooseberry.colander`

## Как откатить одной командой (grep+sed)
```bash
# Восстановить prod bundle ID (запускать из корня проекта)
find . -name "*.swift" -o -name "*.entitlements" -o -name "*.pbxproj" | \
  xargs sed -i '' 's/com\.gooseberry\.colanderTest/com.gooseberry.colander/g'
```

## Что НЕ нужно откатывать (это фича, не тест)
- SubscriptionService.swift — новый файл
- ServerRepository.swift — новый файл
- Изменения в ServiceVPN1View.swift, ServiceVPN1ViewModel.swift, VPNConnectionService.swift (кроме bundle ID) — это фича импорта подписок
