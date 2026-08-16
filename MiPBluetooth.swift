import Foundation
import CoreBluetooth

final class MiPBluetooth: NSObject, ObservableObject {
    @Published var stateText = "Disconnected"
    @Published var isConnected = false
    @Published var devices: [CBPeripheral] = []

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var driveTimer: Timer?

    private let serviceUUID = CBUUID(string: "FFE5")
    private let writeUUID = CBUUID(string: "FFE9")

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func scan() {
        guard central.state == .poweredOn else {
            stateText = "Turn Bluetooth on"
            return
        }
        devices.removeAll()
        stateText = "Scanning..."
        central.scanForPeripherals(withServices: [serviceUUID],
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScan() {
        central.stopScan()
        if !isConnected { stateText = "Disconnected" }
    }

    func connect(_ p: CBPeripheral) {
        stopScan()
        peripheral = p
        p.delegate = self
        stateText = "Connecting..."
        central.connect(p, options: nil)
    }

    func disconnect() {
        stopDrive()
        if let p = peripheral {
            central.cancelPeripheralConnection(p)
        }
    }

    // MiP protocol: 0x78 = continuous drive.
    // Forward: 0x01...0x20, backward: 0x21...0x40,
    // right spin: 0x41...0x60, left spin: 0x61...0x80.
    func startDrive(_ command: UInt8) {
        guard writeCharacteristic != nil else { return }
        stopDrive()
        send([0x78, command])
        driveTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.send([0x78, command])
        }
    }

    func stopDrive() {
        driveTimer?.invalidate()
        driveTimer = nil
        send([0x77])
    }

    func setChestLED(r: UInt8, g: UInt8, b: UInt8) {
        send([0x84, r, g, b])
    }

    func dance() { send([0x76, 0x04]) }
    func stack() { send([0x76, 0x06]) }
    func roam() { send([0x76, 0x08]) }
    func tracking() { send([0x76, 0x03]) }
    func getUp() { send([0x23, 0x02]) }

    private func send(_ bytes: [UInt8]) {
        guard let p = peripheral, let c = writeCharacteristic else { return }
        p.writeValue(Data(bytes), for: c, type: .withoutResponse)
    }
}

extension MiPBluetooth: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            stateText = "Bluetooth ready"
        case .poweredOff:
            stateText = "Bluetooth is off"
        case .unauthorized:
            stateText = "Bluetooth permission denied"
        case .unsupported:
            stateText = "Bluetooth not supported"
        default:
            stateText = "Bluetooth unavailable"
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        if !devices.contains(where: { $0.identifier == peripheral.identifier }) {
            devices.append(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        isConnected = true
        stateText = "Connected"
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        stateText = "Connection failed"
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        stopDrive()
        isConnected = false
        writeCharacteristic = nil
        stateText = "Disconnected"
    }
}

extension MiPBluetooth: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral,
                     didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == serviceUUID {
            peripheral.discoverCharacteristics([writeUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                     didDiscoverCharacteristicsFor service: CBService,
                     error: Error?) {
        guard let chars = service.characteristics else { return }
        writeCharacteristic = chars.first(where: { $0.uuid == writeUUID })
        if writeCharacteristic != nil {
            stateText = "MiP ready"
            // Put MiP in App mode.
            send([0x76, 0x01])
        }
    }
}
