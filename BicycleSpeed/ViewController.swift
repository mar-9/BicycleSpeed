//
//  ViewController.swift
//  bicycleApp
//
//  Created by Mar 9 on 2021/12/10.
//  
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    struct Constants {
        static let ScanSegue = "ScanSegue"
        static let SensorUserDefaultsKey = "lastsensorused"
    }
    
    var bluetoothManager:BluetoothManager!
    var sensor:CadenceSensor?
    weak var scanViewController:ScanViewController?
    var infoViewController:InfoTableViewController?
    var accumulatedDistance:Double?
    
    lazy var distanceFormatter:LengthFormatter = {
        let formatter = LengthFormatter()
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()
    
    //@IBOutlet var labelBTStatus:UILabel!
    @IBOutlet var scanItem:UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        bluetoothManager = BluetoothManager()
        bluetoothManager.bluetoothDelegate = self
        scanItem.isEnabled = false
    }
    
    deinit {
        disconnectSensor()
    }
    
    @IBAction func unwindSegue( segue:UIStoryboardSegue ) {
        bluetoothManager.stopScan()
        guard let sensor = (segue as? ScanUnwindSegue)?.sensor else {
            return
        }
        print("Need to connect to sensor \(sensor.peripheral.identifier.uuidString)")
        connectToSensor(sensor: sensor)
    }

    func disconnectSensor( ) {
        if sensor != nil  {
            bluetoothManager.disconnectSensor(sensor: sensor!)
            sensor = nil
        }
        accumulatedDistance = nil
    }

    func connectToSensor(sensor:CadenceSensor) {
        self.sensor  = sensor
        bluetoothManager.connectToSensor(sensor: sensor)
        // Save the sensor ID
        UserDefaults.standard.set(sensor.peripheral.identifier.uuidString, forKey: Constants.SensorUserDefaultsKey)
        UserDefaults.standard.synchronize()
    }

    // TODO: REconnect. Try this every X seconds
    func checkPreviousSensor() {
        guard let sensorID = UserDefaults.standard.object(forKey: Constants.SensorUserDefaultsKey)  as? String else {
            return
        }
        guard let sensor = bluetoothManager.retrieveSensorWithIdentifier(identifier: sensorID) else {
            return
        }
        print("reconnect success.")
        self.sensor = sensor
        connectToSensor(sensor: sensor)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let infoVC = segue.destination as? InfoTableViewController {
            infoViewController = infoVC
        }
        if segue.identifier == Constants.ScanSegue {
            // Scan segue
            bluetoothManager.startScan()
            scanViewController  = (segue.destination as? UINavigationController)?.viewControllers.first as? ScanViewController
        }
    }
}


extension ViewController : CadenceSensorDelegate {
  
    func errorDiscoveringSensorInformation(error: NSError) {
        print("An error ocurred disconvering the sensor services/characteristics: \(error)")
    }

    func sensorReady() {
        print("Sensor ready to go...")
        accumulatedDistance = 0.0
    }

    func updateSensorInfo() {
        let name = sensor?.peripheral.name ?? ""
        let uuid = sensor?.peripheral.identifier.uuidString ?? ""

        OperationQueue.main.addOperation { () -> Void in
            self.infoViewController?.showDeviceName(name: name , uuid:uuid )
        }
    }
  
    func sensorUpdatedValues( speedInMetersPerSecond speed:Double?, cadenceInRpm cadence:Double?, distanceInMeters distance:Double? ) {

        accumulatedDistance? += distance ?? 0
        let distanceText = (accumulatedDistance != nil && accumulatedDistance! >= 1.0) ? distanceFormatter.string(fromMeters: accumulatedDistance!) : "N/A"
        let speedText = (speed != nil) ? distanceFormatter.string(fromValue: speed!*3.6, unit: .kilometer) + NSLocalizedString("/h", comment:"(km) Per hour") : "N/A"
        let cadenceText = (cadence != nil) ? String(format: "%.2f %@",  cadence!, NSLocalizedString("RPM", comment:"Revs per minute") ) : "N/A"

        OperationQueue.main.addOperation { () -> Void in
            self.infoViewController?.showMeasurementWithSpeed(speed: speedText , cadence: cadenceText, distance: distanceText )
        }
    }
}

extension ViewController: BluetoothManagerDelegate {
  
    func stateChanged(state: CBManagerState) {
        print("State Changed: \(state)")
        var enabled = false
        var title = ""
        switch state {
        case .poweredOn:
            print("Bluetooth ON")
            title = "Bluetooth ON"
            enabled = true
            // When the bluetooth changes to ON, try to reconnect to the previous sensor
            checkPreviousSensor()
        case .resetting:
            print("Reseeting")
            title = "Reseeting"
        case .poweredOff:
            print("Bluetooth Off")
          title = "Bluetooth Off"
        case .unauthorized:
            print("Bluetooth not authorized")
          title = "Bluetooth not authorized"
        case .unknown:
            print("Unknown")
          title = "Unknown"
        case .unsupported:
            print("Bluetooth not supported")
          title = "Bluetooth not supported"
        @unknown default:
            break;
        }
        infoViewController?.showBluetoothStatusText( text: title )
        scanItem.isEnabled = enabled
    }

    func sensorConnection( sensor:CadenceSensor, error:Error?) {
        print("")
        guard error == nil else {
            self.sensor = nil
            print("Error connecting to sensor: \(sensor.peripheral.identifier)")
            updateSensorInfo()
            accumulatedDistance = nil
            return
        }
        self.sensor = sensor
        self.sensor?.sensorDelegate = self
        print("Sensor connected. \(String(describing: sensor.peripheral.name)). [\(sensor.peripheral.identifier)]")
        updateSensorInfo()

        sensor.start()
    }

    func sensorDisconnected( sensor:CadenceSensor, error:Error?) {
        print("Sensor disconnected")
        self.sensor = nil
    }

    func sensorDiscovered( sensor:CadenceSensor ) {
        scanViewController?.addSensor(sensor: sensor)
    }
}
