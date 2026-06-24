# Быстрая настройка с платным аккаунтом

## 🎯 Что нужно сделать прямо сейчас

### 1. В Apple Developer Portal

1. **Создайте/проверьте App IDs:**
   - Основное приложение: `com.gooseberry.colander` (или ваш Bundle ID)
   - Extension: `com.gooseberry.colander.tunnel` (уже настроен)

2. **Включите Capabilities для Extension App ID:**
   - ✅ App Groups
   - ✅ Personal VPN (Packet Tunnel)

3. **Включите Capabilities для основного App ID:**
   - ✅ App Groups

4. **Создайте Provisioning Profiles:**
   - Development profile для обоих App IDs
   - Distribution profile для обоих App IDs

### 2. В Xcode

#### Основное приложение (FastVPNApp):

1. **Signing & Capabilities:**
   - Выберите вашу Team
   - + Capability → **App Groups**
   - Добавьте: `group.com.asdf.FastVPNApp` (или создайте свою группу)

#### Extension (FastVPNAppPacketTunnel):

1. **Signing & Capabilities:**
   - Выберите **ту же** Team
   - + Capability → **App Groups**
   - Добавьте **ту же** группу: `group.com.asdf.FastVPNApp`
   - + Capability → **Personal VPN**
   - Убедитесь, что "Packet Tunnel" выбран

2. **Проверьте Bundle Identifier:**
   - Должен быть: `com.gooseberry.colander.tunnel` (или ваш)
   - Должен быть поддоменом основного Bundle ID

### 3. Проверка зависимостей

1. Target `FastVPNApp` → Build Phases:
   - ✅ Dependencies: должен быть `FastVPNAppPacketTunnel`
   - ✅ Embed Foundation Extensions: должен быть `FastVPNAppPacketTunnel.appex`

### 4. Обновите App Group в коде (если изменили)

Если создали свою App Group (не `group.com.asdf.FastVPNApp`), обновите в:

- `VPNConnectionService.swift` → `appGroupIdentifier`
- `FastVPNApp.entitlements`
- `FastVPNAppPacketTunnel.entitlements`

## 🚀 Тестирование

1. Подключите iPhone/iPad
2. Выберите устройство в Xcode
3. Product → Run
4. Проверьте, что оба targets собираются
5. Проверьте, что приложение устанавливается

## 📦 Codemagic

После настройки в Xcode, в Codemagic используйте:

```yaml
scripts:
  - name: Build with Extension
    script: |
      xcodebuild clean build \
        -project FastVPNApp.xcodeproj \
        -scheme FastVPNApp \
        -configuration Release \
        -sdk iphoneos \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM="$APP_STORE_CONNECT_TEAM_ID"
```

## ✅ Чеклист

- [ ] App IDs созданы в Developer Portal
- [ ] Capabilities включены в App IDs
- [ ] Provisioning Profiles созданы
- [ ] App Groups добавлен в оба targets в Xcode
- [ ] Personal VPN добавлен в Extension target
- [ ] Code Signing настроен для обоих targets
- [ ] Проект собирается без ошибок
- [ ] Приложение устанавливается на устройство

## ⚠️ Важно

- **Оба targets должны использовать одну и ту же Team**
- **App Group должна быть одинаковой в обоих targets**
- **Extension Bundle ID должен быть поддоменом основного**

Готово! Теперь можно тестировать VPN подключение. 🎉


