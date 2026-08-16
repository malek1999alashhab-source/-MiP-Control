# MiP Control

iPhone SwiftUI controller for Coder MiP.

## Current status
The GitHub Actions workflow builds an **unsigned** iPhone app on a free public macOS runner.

Important: an unsigned `.app` cannot be installed directly on a normal iPhone. Apple requires the app to be provisioned/signed for device installation. A free Personal Team can provision apps for 7 days, but Apple manages that provisioning through Xcode on a signed-in Mac. We therefore use the GitHub build first to verify that the project compiles, then choose a safe signing/install route.

## Hardware
- iPhone
- WowWee Coder MiP
- Bluetooth enabled

## Features in v2
- BLE scan/connect
- touch joystick
- stop
- chest LED colors
- Dance / Stack / Roam / Get Up

Protocol basis: WowWee MiP BLE protocol.
