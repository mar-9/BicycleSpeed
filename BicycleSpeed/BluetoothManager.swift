//
//  BluetoothManager.swift
//  bicycleApp
//
//  Created by Mar 9 on 2021/12/10.
//  
//

import Foundation
import CoreBluetooth

protocol BluetoothManagerDelegate {
    func stateChanged(state:CBManagerState)
    func sensorDiscovered( sensor:CadenceSensor )
    func sensorConnection( sensor:CadenceSensor, error:Error?)
    func sensorDisconnected( sensor:CadenceSensor, error:Error?)
}

class BluetoothManager: NSObject, CBPeripheralDelegate  {
  
    let bluetoothCentral:CBCentralManager
    var bluetoothDelegate:BluetoothManagerDelegate?
    let servicesToScan = [CBUUID(string: BTConstants.CadenceService)]
  
    override init() {
        bluetoothCentral = CBCentralManager()
        super.init()
        bluetoothCentral.delegate = self
    }

    deinit {
        stopScan()
    }

    func startScan() {
//        bluetoothCentral.scanForPeripherals(withServices: nil, options: nil )
        bluetoothCentral.scanForPeripherals(withServices: [
            CBUUID(string: "1814"),
            CBUUID(string: "1816")
        ], options: nil )
    }

    func stopScan() {
        if bluetoothCentral.isScanning {
            bluetoothCentral.stopScan()
        }
    }

    func connectToSensor(sensor:CadenceSensor) {
        // just in case, disconnect pending connections first
        disconnectSensor(sensor: sensor)
        bluetoothCentral.connect(sensor.peripheral, options: nil)
    }

    func disconnectSensor(sensor:CadenceSensor) {
        bluetoothCentral.cancelPeripheralConnection(sensor.peripheral)
    }

    func retrieveSensorWithIdentifier( identifier:String ) -> CadenceSensor? {
        let uuid = UUID(uuidString: identifier)
        let nsmArray1 : [UUID]  = [uuid!]
        guard let peripheral = bluetoothCentral.retrievePeripherals(withIdentifiers: nsmArray1).first else {
            return nil
        }
        return CadenceSensor(peripheral: peripheral)
    }
}

extension BluetoothManager:CBCentralManagerDelegate {
  
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothDelegate?.stateChanged(state: central.state)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Peripeherals name:\(peripheral.name ?? "")")
        let sensor = CadenceSensor(peripheral: peripheral)
        bluetoothDelegate?.sensorDiscovered(sensor: sensor)
    }
  
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("did connect")
        bluetoothDelegate?.sensorConnection(sensor: CadenceSensor(peripheral: peripheral), error: nil)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("did didConnectPeripheral")
        bluetoothDelegate?.sensorConnection(sensor: CadenceSensor(peripheral: peripheral), error: nil)
    }
  
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        bluetoothDelegate?.sensorConnection(
            sensor: CadenceSensor(peripheral: peripheral),
            error: error
        )
    }
}
