//
//  InfoTableViewController.swift
//  bicycleApp
//
//  Created by Mar 9 on 2021/12/11.
//  
//


import UIKit

class InfoTableViewController: UITableViewController {

    private struct Constants {
        static let BluetoothStatusSection=0
        static let DeviceSectionSection=1
        static let MeasurementsSection=2
        static let BluetoothStatusRow = 0
        static let DeviceNameRow = 0
        static let DeviceUUIDRow = 1
        static let SpeedRow = 0
        static let CadenceRow = 1
        static let DistanceRow = 2
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func showBluetoothStatusText( text:String ) {
        showDetailText(text: text, atSection: Constants.BluetoothStatusSection, row:Constants.BluetoothStatusRow)
    }

    func showDeviceName( name:String? , uuid:String? ) {
        showDetailText(text: name ?? "", atSection: Constants.DeviceSectionSection, row:Constants.DeviceNameRow)
        showDetailText(text: uuid ?? "", atSection: Constants.DeviceSectionSection, row:Constants.DeviceUUIDRow)
    }

    func showMeasurementWithSpeed( speed:String, cadence:String, distance:String  ) {
        showDetailText(text: speed, atSection: Constants.MeasurementsSection, row:Constants.SpeedRow)
        showDetailText(text: cadence, atSection: Constants.MeasurementsSection, row:Constants.CadenceRow)
        showDetailText(text: distance, atSection: Constants.MeasurementsSection, row:Constants.DistanceRow)
    }

    func showDetailText( text:String , atSection section:Int, row:Int) {
        if let cell  = tableView.cellForRow(at: IndexPath(row: row, section: section)) {
        cell.detailTextLabel?.text = text
        }
    }
}
