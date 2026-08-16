import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @EnvironmentObject var ble: MiPBluetooth
    @State private var joystick = CGSize.zero

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statusCard

                    if !ble.isConnected {
                        Button("🔎 Scan for MiP") { ble.scan() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)

                        ForEach(ble.devices, id: \.identifier) { device in
                            Button {
                                ble.connect(device)
                            } label: {
                                HStack {
                                    Image(systemName: "dot.radiowaves.left.and.right")
                                    Text(device.name ?? "MiP")
                                    Spacer()
                                    Text("Connect")
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Text("JOYSTICK")
                            .font(.headline)

                        Joystick(size: 220, knob: $joystick) { point in
                            driveFrom(point)
                        } onEnd: {
                            ble.stopDrive()
                        }

                        Button {
                            ble.stopDrive()
                            joystick = .zero
                        } label: {
                            Text("STOP")
                                .font(.headline)
                                .frame(width: 110, height: 54)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)

                        ledSection
                        modeSection

                        Button("Disconnect") { ble.disconnect() }
                            .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("MiP Control")
        }
    }

    private var statusCard: some View {
        VStack(spacing: 7) {
            Image(systemName: ble.isConnected ? "checkmark.circle.fill" : "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 34))
            Text(ble.stateText).font(.headline)
            Text("Coder MiP • Bluetooth LE")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var ledSection: some View {
        VStack(spacing: 10) {
            Text("Chest LED").font(.headline)
            HStack {
                led("Red", .red) { ble.setChestLED(r: 255, g: 0, b: 0) }
                led("Green", .green) { ble.setChestLED(r: 0, g: 255, b: 0) }
                led("Blue", .blue) { ble.setChestLED(r: 0, g: 0, b: 255) }
                led("White", .gray) { ble.setChestLED(r: 255, g: 255, b: 255) }
            }
        }
    }

    private var modeSection: some View {
        VStack(spacing: 10) {
            Text("Modes").font(.headline)
            HStack {
                Button("Dance") { ble.dance() }
                Button("Stack") { ble.stack() }
                Button("Roam") { ble.roam() }
                Button("Get Up") { ble.getUp() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    private func led(_ title: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .tint(color)
    }

    private func driveFrom(_ p: CGPoint) {
        let x = p.x
        let y = p.y
        let magnitude = sqrt(x*x + y*y)
        guard magnitude > 0.15 else {
            ble.stopDrive()
            return
        }

        if abs(x) > abs(y) {
            ble.startDrive(x > 0 ? 0x50 : 0x70)
        } else {
            ble.startDrive(y < 0 ? 0x10 : 0x30)
        }
    }
}

struct Joystick: View {
    let size: CGFloat
    @Binding var knob: CGSize
    let onMove: (CGPoint) -> Void
    let onEnd: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .fill(.thinMaterial)
                .overlay(Circle().stroke(.secondary, lineWidth: 2))
            Circle()
                .fill(.blue.opacity(0.85))
                .frame(width: size * 0.36, height: size * 0.36)
                .offset(knob)
        }
        .frame(width: size, height: size)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let radius = size * 0.32
                    let dx = value.translation.width
                    let dy = value.translation.height
                    let d = sqrt(dx*dx + dy*dy)
                    let scale = d > radius ? radius / d : 1
                    knob = CGSize(width: dx * scale, height: dy * scale)
                    onMove(CGPoint(x: knob.width / radius, y: knob.height / radius))
                }
                .onEnded { _ in
                    knob = .zero
                    onEnd()
                }
        )
    }
}
