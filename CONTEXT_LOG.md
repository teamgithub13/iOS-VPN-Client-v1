# Context log (auto)

## Goal
- Make WireGuard VPN actually work (WireGuardKit integration) and keep local macOS build viable.
- Codemagic workarounds were attempted, then reverted; Codemagic still fails due to missing /usr/bin/make.

## Key code changes
- WireGuardKit integration:
  - `FastVPNAppPacketTunnel/Protocols/WireGuardTunnel.swift`
    - Uses `WireGuardAdapter`.
    - Builds wg-quick config with interface address, DNS, allowed IPs, endpoint, optional preshared key.
    - Starts/stops adapter instead of placeholder packet loop.
  - `FastVPNAppPacketTunnel/PacketTunnelProvider.swift`
    - WireGuard start uses adapter; no manual `setTunnelNetworkSettings`.
    - stop uses adapter callback.

- WireGuard config model + parsing:
  - Added `interfaceAddress` to both app and extension models:
    - `FastVPNApp/Service/Models/VPNConfiguration.swift`
    - `FastVPNAppPacketTunnel/Models/VPNConfiguration.swift`
  - Parser now stores `[Interface] Address` in `interfaceAddress` and uses `Endpoint` for remote address/port:
    - `FastVPNApp/Service/Services/VPNConfigurationService.swift`
    - If `Endpoint` missing -> parse returns nil (required for WireGuard).

## Codemagic status (reverted)
- All Codemagic-specific workarounds were removed; `codemagic.yaml` restored to pre-workaround state.
- Root cause on Codemagic: `WireGuardGoBridgeiOS` invokes `/usr/bin/make` (missing in Codemagic image).

## Xcode project setting
- `FastVPNApp.xcodeproj/project.pbxproj`
  - `WireGuardGoBridgeiOS` legacy target uses `buildToolPath = /usr/bin/make` (restored).

## Current known issues
- Codemagic archive fails: missing `/usr/bin/make` in their environment.
  - Fix would require either a Codemagic image that has /usr/bin/make, or changing the legacy target/tool path in CI only.

## Suggested next steps (if needed)
- Local macOS build: ensure CLT installed (`/usr/bin/make` present), then build in Xcode.
- For CI: either use an image with `/usr/bin/make` or add a CI-only patch to legacy target build tool path.
