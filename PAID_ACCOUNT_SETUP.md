# Настройка проекта с платным Apple Developer аккаунтом

## ✅ Что нужно настроить

### 1. App Groups для обоих targets

#### В Xcode:

**Для основного приложения (FastVPNApp):**
1. Выберите target `FastVPNApp`
2. Signing & Capabilities → + Capability
3. Выберите **App Groups**
4. Добавьте группу: `group.com.asdf.FastVPNApp`
5. Убедитесь, что галочка стоит

**Для Extension (FastVPNAppPacketTunnel):**
1. Выберите target `FastVPNAppPacketTunnel`
2. Signing & Capabilities → + Capability
3. Выберите **App Groups**
4. Добавьте **ту же** группу: `group.com.asdf.FastVPNApp`
5. Убедитесь, что галочка стоит

### 2. Personal VPN для Extension

**Для Extension (FastVPNAppPacketTunnel):**
1. Выберите target `FastVPNAppPacketTunnel`
2. Signing & Capabilities → + Capability
3. Выберите **Personal VPN**
4. Убедитесь, что **Packet Tunnel** выбран

### 3. Code Signing

#### В Xcode:

**Для основного приложения:**
1. Выберите target `FastVPNApp`
2. Signing & Capabilities
3. Выберите вашу Team
4. Убедитесь, что "Automatically manage signing" включено
5. Или настройте вручную Provisioning Profile

**Для Extension:**
1. Выберите target `FastVPNAppPacketTunnel`
2. Signing & Capabilities
3. Выберите **ту же** Team
4. Убедитесь, что "Automatically manage signing" включено
5. Или настройте Provisioning Profile вручную

### 4. Bundle Identifiers

Убедитесь, что Bundle Identifiers правильные:

- **Основное приложение:** `com.asdf.FastVPNApp`
- **Extension:** `com.asdf.FastVPNApp.PacketTunnel` (или `com.asdf.FastVPNApp.FastVPNAppPacketTunnel`)

Проверьте в Build Settings → Product Bundle Identifier

### 5. Проверка зависимостей

Убедитесь, что основной target зависит от Extension:

1. Выберите target `FastVPNApp`
2. Build Phases → Dependencies
3. Должна быть зависимость `FastVPNAppPacketTunnel`

4. Build Phases → Embed Foundation Extensions
5. Должен быть `FastVPNAppPacketTunnel.appex`

## 🔧 Настройка Codemagic

### Вариант 1: Автоматическая подпись (Рекомендуется)

В `codemagic.yaml`:

```yaml
workflows:
  ios-workflow:
    name: iOS Workflow
    max_build_duration: 120
    instance_type: mac_mini_m1
    environment:
      groups:
        - app_store_credentials  # Ваши credentials
      vars:
        XCODE_WORKSPACE: "FastVPNApp.xcodeproj"
        XCODE_SCHEME: "FastVPNApp"
        BUNDLE_ID: "com.asdf.FastVPNApp"
        APP_STORE_ID: "your-app-id"  # Если есть
    scripts:
      - name: Set up code signing
        script: |
          xcode-project use-profiles
      - name: Build iOS app
        script: |
          xcodebuild clean build \
            -project "$XCODE_WORKSPACE" \
            -scheme "$XCODE_SCHEME" \
            -configuration Release \
            -sdk iphoneos \
            -destination 'generic/platform=iOS' \
            CODE_SIGN_STYLE=Automatic \
            DEVELOPMENT_TEAM="$APP_STORE_CONNECT_TEAM_ID" \
            PROVISIONING_PROFILE_SPECIFIER=""
      - name: Build IPA
        script: |
          xcodebuild archive \
            -project "$XCODE_WORKSPACE" \
            -scheme "$XCODE_SCHEME" \
            -configuration Release \
            -archivePath build/FastVPNApp.xcarchive \
            CODE_SIGN_STYLE=Automatic \
            DEVELOPMENT_TEAM="$APP_STORE_CONNECT_TEAM_ID"
          
          xcodebuild -exportArchive \
            -archivePath build/FastVPNApp.xcarchive \
            -exportOptionsPlist exportOptions.plist \
            -exportPath build/ipa
    artifacts:
      - build/ipa/*.ipa
```

### Вариант 2: Ручная настройка Provisioning Profiles

Если используете ручные профили:

1. **Создайте App ID в Apple Developer Portal:**
   - Основное приложение: `com.asdf.FastVPNApp`
   - Extension: `com.asdf.FastVPNApp.PacketTunnel`

2. **Включите Capabilities:**
   - App Groups для обоих App IDs
   - Personal VPN для Extension App ID

3. **Создайте Provisioning Profiles:**
   - Development profile для обоих App IDs
   - Distribution profile для обоих App IDs

4. **В Codemagic:**
   - Загрузите profiles в Codemagic
   - Используйте их в настройках

### Настройка exportOptions.plist

Создайте файл `exportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>  <!-- или app-store, ad-hoc, enterprise -->
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.asdf.FastVPNApp</key>
        <string>Your Main App Profile Name</string>
        <key>com.asdf.FastVPNApp.PacketTunnel</key>
        <string>Your Extension Profile Name</string>
    </dict>
</dict>
</plist>
```

## ✅ Чеклист настройки

### В Apple Developer Portal:

- [ ] Создан App ID для основного приложения
- [ ] Создан App ID для Extension
- [ ] Включен App Groups capability для обоих App IDs
- [ ] Включен Personal VPN capability для Extension App ID
- [ ] Созданы Provisioning Profiles (Development и Distribution)
- [ ] Profiles загружены в Codemagic (если используете ручные)

### В Xcode:

- [ ] App Groups добавлен в оба targets
- [ ] Personal VPN добавлен в Extension target
- [ ] Code Signing настроен для обоих targets
- [ ] Bundle Identifiers правильные
- [ ] Зависимость Extension от основного target настроена
- [ ] Embed Foundation Extensions настроен

### В Codemagic:

- [ ] Credentials настроены
- [ ] Team ID указан
- [ ] Схема сборки правильная
- [ ] Provisioning Profiles загружены (если ручные)

## 🧪 Тестирование

### На реальном устройстве:

1. Подключите iPhone/iPad
2. Выберите устройство в Xcode
3. Запустите приложение
4. Добавьте VPN конфигурацию
5. Попробуйте подключиться

### Проверка работы:

- ✅ Приложение устанавливается
- ✅ Extension устанавливается вместе с app
- ✅ Конфигурация сохраняется
- ✅ VPN подключается (после интеграции библиотек)

## ⚠️ Важные замечания

1. **Оба targets должны быть подписаны одной и той же Team**
2. **App Groups должны быть одинаковыми в обоих targets**
3. **Extension Bundle ID должен быть поддоменом основного**
4. **Provisioning Profiles должны включать все необходимые capabilities**

## 🐛 Решение проблем

### Ошибка "No profiles for 'com.asdf.FastVPNApp.PacketTunnel'"

**Решение:**
- Создайте App ID для Extension в Developer Portal
- Включите все необходимые capabilities
- Создайте Provisioning Profile
- Обновите в Xcode

### Ошибка "App Groups entitlement is missing"

**Решение:**
- Проверьте, что App Groups добавлен в оба targets в Xcode
- Проверьте, что группа одинаковая: `group.com.asdf.FastVPNApp`
- Проверьте, что App Groups включен в App IDs в Developer Portal

### Ошибка "Personal VPN entitlement is missing"

**Решение:**
- Проверьте, что Personal VPN добавлен в Extension target
- Проверьте, что Personal VPN включен в Extension App ID в Developer Portal
- Проверьте Provisioning Profile

## 📝 Следующие шаги

После настройки:

1. ✅ Протестируйте сборку в Xcode
2. ✅ Протестируйте на реальном устройстве
3. ✅ Настройте Codemagic для CI/CD
4. ✅ Интегрируйте библиотеки (WireGuardKit, v2ray-core, shadowsocks)
5. ✅ Протестируйте реальные VPN подключения

Удачи! 🚀


