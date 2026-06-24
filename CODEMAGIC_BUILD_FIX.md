# Исправление ошибки сборки на Codemagic

## Проблема

```
error: "FastVPNAppPacketTunnel" requires a provisioning profile with the App Groups and Personal VPN features.
```

Это происходит потому, что:
1. Основной target `FastVPNApp` зависит от `FastVPNAppPacketTunnel`
2. Network Extension требует платный Apple Developer аккаунт
3. Codemagic пытается собрать оба targets

## Решение

### Вариант 1: Собирать только основной target (Рекомендуется)

В настройках Codemagic измените команду сборки:

**Вместо:**
```yaml
xcodebuild -project FastVPNApp.xcodeproj -scheme FastVPNApp
```

**Используйте:**
```yaml
xcodebuild -project FastVPNApp.xcodeproj -target FastVPNApp -configuration Release
```

Это соберет только основной target без Extension.

### Вариант 2: Убрать зависимость в Xcode (Временно)

Если нужно собрать через схему, временно уберите зависимость:

1. В Xcode выберите target `FastVPNApp`
2. Build Phases → Dependencies
3. Удалите зависимость `FastVPNAppPacketTunnel`
4. Build Phases → Embed Foundation Extensions
5. Удалите эту фазу (или уберите из неё Extension)

**⚠️ ВАЖНО:** После этого Extension не будет встроен в приложение, но проект соберется.

### Вариант 3: Создать отдельную схему без Extension

1. В Xcode: Product → Scheme → Manage Schemes
2. Дублируйте схему `FastVPNApp`
3. Назовите её `FastVPNApp-NoExtension`
4. В настройках схемы уберите `FastVPNAppPacketTunnel` из Build targets
5. В Codemagic используйте эту схему

### Вариант 4: Условная сборка в Codemagic

В `codemagic.yaml`:

```yaml
workflows:
  ios-workflow:
    name: iOS Workflow
    max_build_duration: 120
    instance_type: mac_mini_m1
    environment:
      groups:
        - app_store_credentials
      vars:
        XCODE_WORKSPACE: "FastVPNApp.xcodeproj"
        XCODE_SCHEME: "FastVPNApp"
        BUNDLE_ID: "com.asdf.FastVPNApp"
    scripts:
      - name: Build only main target
        script: |
          xcodebuild clean -project "$XCODE_WORKSPACE" -scheme "$XCODE_SCHEME" -configuration Release \
            -sdk iphoneos \
            -destination 'generic/platform=iOS' \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO \
            ONLY_ACTIVE_ARCH=NO \
            -target FastVPNApp
```

## Рекомендуемое решение для Codemagic

### В codemagic.yaml:

```yaml
scripts:
  - name: Build iOS app without Extension
    script: |
      xcodebuild clean build \
        -project FastVPNApp.xcodeproj \
        -target FastVPNApp \
        -configuration Release \
        -sdk iphoneos \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO
```

### Или через схему (если создали отдельную):

```yaml
scripts:
  - name: Build iOS app
    script: |
      xcodebuild clean build \
        -project FastVPNApp.xcodeproj \
        -scheme FastVPNApp-NoExtension \
        -configuration Release \
        -sdk iphoneos \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO
```

## Что будет работать

✅ Основное приложение соберется
✅ UI будет работать
✅ Парсинг конфигураций будет работать
✅ Все функции кроме реального VPN подключения

## Что НЕ будет работать

❌ Network Extension не соберется (но это и не нужно без платного аккаунта)
❌ Реальное VPN подключение (требует Extension + платный аккаунт)

## Альтернатива: Отключить Extension в коде

Можно временно отключить использование Extension в коде:

В `VPNConnectionService.swift` можно добавить проверку:

```swift
#if !TARGET_EXTENSION
// Код для основного приложения
#else
// Код для Extension
#endif
```

Но это сложнее и не обязательно.

## Итог

**Самое простое решение:** В Codemagic используйте `-target FastVPNApp` вместо `-scheme FastVPNApp`, чтобы собирать только основной target без Extension.


