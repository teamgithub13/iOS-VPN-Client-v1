# Карта навигации приложения (FastVPNApp)

> Заметка для агента: как в приложении открываются экраны.

## Точка входа
- `FastVPNApp/Application/AppDelegate.swift` — `@main`, `UIApplicationDelegate` (НЕ SceneDelegate, НЕ SwiftUI App).
- `window?.rootViewController = OnboardingVPN1ViewController()` → первый экран.
- TabBar появляется только после онбординга.

## Архитектура: UIKit-хост + SwiftUI-контент
Каждый экран = `UIViewController`, который в `viewDidLoad`:
1. Создаёт `UIHostingController(rootView: SomeView(...замыкания...))`
2. Добавляет child VC, пинит к edge constraints
3. Вызывает `vc.didMove(toParent: self)`

Навигация живёт в **UIKit-слое** (замыкания), НЕ в SwiftUI/ViewModel.

## Паттерн открытия экрана (доминирующий — Pattern A)
**Closure-инъекция + `present(_:animated:)` fullScreen modal.** Используется ВЕЗДЕ для межэкранной навигации.

SwiftUI-View объявляет optional-замыкание:
```swift
struct ServiceVPN1View: View {
    var tapSupportAction: (() -> Void)?
    // ... Button { tapSupportAction?() }
}
```

UIViewController инъектирует его и презентует следующий VC:
```swift
let vc = UIHostingController(rootView: ServiceVPN1View(tapSupportAction: {
    let next = SupportVPN1ViewController()
    next.modalPresentationStyle = .fullScreen
    self.present(next, animated: true)
}))
```

Dismiss — тоже через замыкание `dismissVPN1Action: { self.dismiss(animated: true) }`.

## Паттерн B (одно исключение — SwiftUI `.sheet`)
- `ServiceVPN1View.swift:107` — `.sheet(isPresented: $showManualInput)` для `ManualConfigInputView`.
- Это самодостаточный sub-screen внутри Service, не выходящий за пределы экрана — потому SwiftUI `.sheet`, а не отдельный VC.
- `.fullScreenCover`, `.popover`, NavigationStack/NavigationView — НИГДЕ не используются.

## TabBar
`FastVPNApp/TabBar/TabBarVPN1ViewController.swift` — единственный контейнер, `UITabBarController`, 3 таба:

| Tag | Title     | Icon                | VC                          |
|-----|-----------|---------------------|-----------------------------|
| 0   | Service   | serviceVPN1Icon     | ServiceVPN1ViewController   |
| 1   | Speed     | speedVPN1Icon       | SpeedVPN1ViewController     |
| 2   | Settings  | settingsVPN1Icon    | SettingsVPN1ViewController  |

`tintColor = .black`. Нет UINavigationController-обёртки.

⚠️ Хост-VC табов (Service/Speed/Settings) пинят bottom к `safeAreaLayoutGuide.bottomAnchor` (чтобы контент не залезал под таббар). Все более глубокие modal-VC пинят к обычному `view.bottomAnchor`.

## Полное дерево навигации
```
AppDelegate
  → OnboardingVPN1VC  [tabBarVPN1Action]
        → TabBarVPN1VC (fullScreen)
              │ Tab 0 Service: ServiceVPN1VC
              │     → [tapSupportAction] SupportVPN1VC (leaf, dismiss)
              │     + внутренний .sheet → ManualConfigInputView (SwiftUI)
              │
              │ Tab 1 Speed: SpeedVPN1VC
              │     (нет навигации, standalone)
              │
              │ Tab 2 Settings: SettingsVPN1VC
                    → [appSettingsVPN1Action] AppVPN1VC
                    │     → [privacyVPN1Action]  PrivacyPolicyVPN1VC (leaf)
                    │     → [termsVPN1Action]    TermsVPN1VC (leaf)
                    │     → [supportVPN1Action]  SupportVPN1VC (leaf)
                    │
                    → [tunnelSettingsVPN1Action] TunnelSettingsVPN1VC
                    │     → [presetsVPN1Action]  PresetsVPN1VC
                    │     │     → [createRulesVPN1Action] MyRulesVPN1VC (leaf)
                    │     → [routingVPN1Action]  RoutingVPN1VC (leaf)
                    │     → [onDemandVPN1Action] OnDemandVPN1VC (leaf)
                    │     → [pingVPN1Action]     PingVPN1VC (leaf)
                    │
                    → [statisticsVPN1Action] StatisticsVPN1VC (leaf)
```

Примечание: `SupportVPN1VC` достижим из ДВУХ мест (Service → tapSupportAction и Settings>App → supportVPN1Action), это два независимых инстанса на modal-стеке.

## Структура директорий (FastVPNApp/)
```
Application/        AppDelegate.swift, LaunchScreen.storyboard
Onboarding/         OnboardingVPN1{View,ViewController}
TabBar/             TabBarVPN1ViewController (3-tab)
Service/            Service tab (главный VPN-экран)
  ServiceVPN1{View,ViewController,ViewModel}
  Models/           VPNConfiguration, VPNProtocolType
  Services/         ServerRepository, SubscriptionService,
                    VPNConfigurationService, VPNConnectionService
Speed/              Speed tab (тест скорости)
Settings/           Settings tab + все sub-экраны
  App/              AppVPN1{View,VC} → Terms/ Support/ PrivacyPolicy/
  Statistics/       StatisticsVPN1{View,VC}
  TunnelSettings/   TunnelSettingsVPN1{View,VC} → Presets/ Routing/ OnDemand/ Ping/ MyRules/
```

## Правило для новых экранов
При добавлении нового экрана в этом проекте:
1. Создать `XxxVPN1View.swift` (SwiftUI) с optional-замыканиями для действий.
2. Создать `XxxVPN1ViewController.swift` (UIKit) → `UIHostingController(rootView: ...)` + edge constraints.
3. НЕ использовать `@Published`-флаги навигации в ViewModel и НЕ использовать `.fullScreenCover`/NavigationStack.
4. Открывать через closure-инъекцию из родительского VC: `present(next, animated: true)` с `.fullScreen`.
5. Кнопка "назад" — SwiftUI Button, вызывающая инъектированный `dismissVPN1Action`.
