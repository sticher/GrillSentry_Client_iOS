
//
//  EggZact_v2_ViewController.swift
//  EggZact_v2
//
//  Created by Ken Sticher on 9/26/17.
//
//  Modifications for Charts Sept2021
// Modifications for iPhone12 Dec2021
//

import UIKit
import CoreBluetooth
import AVFoundation
import CloudKit
import MobileCoreServices

// definitiomn of key constants available to all files used to implement the DomeTemp amnd Probe Temp Charts feature
var domefileEntryTotalCount: Int = 0
var probefileEntryTotalCount: Int = 0
let domeCaptureTotalCnt = 64000   // max element size of capture array (seconds or 0.5seconds)
let probeCaptureTotalCnt = 64000
let domeSlidingWindowCnt = 30
let probeSlidingWindowCnt = 30

var domeTempArray = [String]()
var probeTempArray = [String]()
var domechartSecondCnt = [Float32]()
var probechartSecondCnt = [Float32]()
var domechartMinuteCnt = [Float32]()
var probechartMinuteCnt = [Float32]()
//var DomeTempvsTimeURL = [String]()

var audioPlayer: AVAudioPlayer?

var domeAlrmIsArmd = false
var probeAlrmIsArmd = false

var DomeTempvsTimeString = ""
var probeTempvsTimeString = ""

var probeAttached = false

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UIDocumentPickerDelegate, UINavigationControllerDelegate, CustomAlertViewDelegate, SaveToFileViewDelegate
{
    
    
    // MARK: Properties
    
   
    
    
    @IBOutlet weak var Command:          UILabel!
    //@IBOutlet weak var Probe:            UILabel!
    
    @IBOutlet weak var settingsButton:   UIButton!
    @IBOutlet weak var batteryButton:    UIButton!
    @IBOutlet weak var RSSILabel:        UILabel!
    
    @IBOutlet weak var blueLED: UIImageView!
    
    
    
    @IBOutlet weak var grlSentry: UIImageView!
   
    @IBOutlet weak var USBChrgButton:    UIButton!
    @IBOutlet weak var RSSIButton: UIButton!
    
    
    @IBOutlet weak var domeChartButton: UIButton!
    
   
    @IBOutlet weak var probeChartButton: UIButton!
   
    @IBOutlet weak var setTempAlrmBttn: UIButton!
    
    @IBOutlet weak var domeAlrmValueDsply: UILabel!
    @IBOutlet weak var probeAlrmValueDsply: UILabel!
    
    @IBOutlet weak var stopDomeTempAlrmBttn: UIButton!
    @IBOutlet weak var stopProbeTempAlrmBttn: UIButton!
    
  //  var DomeTempArray: [String]     // added to reach charting capability - 06/07/2021
 //   var DomeTempvsTimeString = ""
    var DomeTempvsTimeString2 = ""
    
    var centralManager: CBCentralManager!
    var EggZact:        CBPeripheral?
    var sendbuffer:     CBCharacteristic?
    
    var stopWatch            = Timer()
    var startTime:  Double   = 0
    var time:       Double   = 0
    var elapsed:    Double   = 0
    var stopwatchRunning     = false
    
    var isCelcius            = false
    var battVoltage          = 5.0
    var batteryString2       = ""
    var versionString        = ""
    var clientVersionString  = "G3PRTD_v1.0"
 
    var batteryString3      = ""
    var PHYStatusString1    = "PHY"
    
    var RSSIString           = ""
    var RSSIInteger         = 200
    var didTapDisconnect     = false
    
    var displaySwitch: Bool = false
    var ProbeTemp   = 0
    
    var domeTimer:    Timer?
    var probeTimer: Timer?
    var versionTimer: Timer?
    var batteryTimer: Timer?
    var RSSITimer: Timer?
    var USBChrgTimer: Timer?
    var flashBlueLEDTimer: Timer?
    
    var connectCounter:UInt16 = 0
    var blueLEDCntr: Bool = true

    var connectTimer: Timer?
    var alreadyConnected: Bool = false
   
    //var probeAttached = false
    var prvsDomeProbeStts = "1" //double tap memory to select dome or probe scan/freeze stop feature
    
    var serverattachedString = ""
    var scan_selectString = "resume_scanning"
    var scan_tempString = "resume_scanning"
    var passcnt = 1;    //ping pong counter used in Gen2 H/W
    
    
    var degFforProbePacket = "°F"
    
    var graphTempTmr:Timer?
    
    var domefileEntryCounter:UInt16 = 0
    var probefileEntryCounter:UInt16 = 0
    
    var tempSecCaptureCnt:Float32 = 0
    var tempSecCaptureCnt1:Int32 = 0
    var tempSecCaptureCnt2:Int32 = 0

    var tempMinCaptureCnt:Float32 = 0
    
    let domeCaptureDivider = 1  // key constant which set the Graphing capture divide down ratio i.e. a constant of 3 divides the graphing time scale to 1 capture per 3 seconds or 1 caoture every 3 seconds
    let probeCaptureDivider = 1
    
    static var isDirty = true
    
 
    /*
     here come the variuos functions
     */
    // MARK: - BLE commands
    
    func disconnectButtonTapped() {
        
        didTapDisconnect = true
        
        switch scan_selectString {
        case "scan_dome_only":
            scan_tempString = "resume_scanning"
        case "resume_scanning":
            scan_tempString = "scan_dome_only"
        case "scan_probe_only":
            scan_tempString = "scan_dome_only"
        default:
            scan_tempString = "resume_scanning"
        }
        scan_selectString = scan_tempString
        
        sendData("frzdome")
   
    //    centralManager.scanForPeripherals(withServices: nil, options: nil)
        
        do {
            sleep(2)        // 4 seconds for changing scan status
        }
        
        if let EggZact = self.EggZact
        {
            
            centralManager.cancelPeripheralConnection(EggZact) // From your app’s perspective the peripheral is considered disconnected. centralManager:didDisconnectPeripheral is called
            //centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
        
        EggZact = nil
        //sendbuffer = nil
        Command.textColor = UIColor.green
        Command.text = "Disconnect"
        alreadyConnected = false
        settingsButton.isHidden = true
        batteryButton.isHidden  = true
        USBChrgButton.isHidden = true
        RSSIButton.isHidden = true
        RSSILabel.isHidden = true
        domeChartButton.isHidden = true
        probeChartButton.isHidden = true

        stopProbeTempAlrmBttn.isHidden = true
        stopDomeTempAlrmBttn.isHidden = true
        setTempAlrmBttn.isHidden = true
        
        domeAlrmValueDsply.isHidden = true
        probeAlrmValueDsply.isHidden = true
        
        domeTimer?.invalidate()
        probeTimer?.invalidate()
        batteryTimer?.invalidate()
    }
    
    func closeButtonTapped() {
        print("closeButtonTapped")
        setTempAlrmBttn.isHidden = false
    }
    
    func changeUnits(selectedOption: String) {
        isCelcius = !isCelcius
        switch selectedOption as String
        {
        case "°C": sendData("degC")
        case "°F": sendData("degF")
        default: break;
        }
        print(isCelcius)
    }
    
    func CalON() {
        if (serverattachedString == "Gen3.0")
        {
            sendData("offsetdwn")
        }
        else
        {
            sendData("calerase")
        }
    }
    
    func CalOFF() {
        if (serverattachedString == "Gen3.0")
        { sendData("offsetup")
        }
        else
        {
            sendData("calwrite")
        }
    }
    
    func VrefUP() {
        if (serverattachedString == "Gen20120")
        { sendData("vrefup")
        }
        else
        { sendData("gainup")
        }
    }
    
    func VrefDOWN() {
        if (serverattachedString == "Gen20120")
        {
            sendData("vrefdwn")
        }
        else{
            sendData("gaindwn")
        }
    }
    
    func EnableCalibration() {
        print("reached enable calibration button press")
    }

    func sendData (_ message: String) {
    if let data = (message + "\r").data(using: String.Encoding.utf8)
    {
        if let EggZact = self.EggZact
        {
            EggZact.writeValue(data as Data, for: self.sendbuffer!, type: .withResponse)
            //print("\(message) command sent to EggZact")
        }
    }
}
    
    @objc func pingforDome(){  sendData("tempOn") }// { sendData("xmtdome") }

    @objc func pingforProbe(){ sendData("xmtprobe") }

    @objc func pingforVersion(){ sendData("version") }

    @objc func pingForBattery(){ sendData("battvolt") }
    
    @objc func pingforRSSI(){ sendData("rssiget")}
    
    @objc func pingforUSBChrg(){ sendData("battchrg")}
    
    func tempON(){ sendData("tempOn") }
    
    func tempOFF(){ sendData("tempOff") }
    
    @IBAction func Connect(_ sender: Any) {
    if alreadyConnected {return}
    if let EggZact = self.EggZact
    {
        centralManager.connect(EggZact, options: nil)
        settingsButton.isHidden   = false
        
    }
}
    @IBAction func ToggleProbeScan(_ sender: Any) {
        
        switch scan_selectString {
        case "scan_probe_only":
            scan_tempString = "resume_scanning"
        case "resume_scanning":
            scan_tempString = "scan_probe_only"
        case "scan_dome_only":
            scan_tempString = "scan_probe_only"
        default:
            scan_tempString = "resume_scanning"
        }
        scan_selectString = scan_tempString
        
        sendData("frzprobe")    // frzprobe command "toggles" the server display    }
    }
    @IBAction func ToggleDomeScan(_ sender: Any) {
        switch scan_selectString {
        case "scan_dome_only":
            scan_tempString = "resume_scanning"
        case "resume_scanning":
            scan_tempString = "scan_dome_only"
        case "scan_probe_only":
            scan_tempString = "scan_dome_only"
        default:
            scan_tempString = "resume_scanning"
        }
        scan_selectString = scan_tempString
        
        sendData("frzdome")
        
    }
    @IBAction func repeatedCommandTap(_ sender: Any) {
       
        if probeAttached == true {
            
            switch prvsDomeProbeStts {
            case "1":
                scan_tempString = "scan_probe_only"
                sendData("frzprobe")    // frzprobe command "toggles" the server display
                scan_selectString = scan_tempString
                prvsDomeProbeStts = "2"
            case "2":
            scan_tempString = "scan_dome_only"
            scan_selectString = scan_tempString
            sendData("frzdome")
            prvsDomeProbeStts = "3"
            case "3":
            scan_tempString = "resume_scanning"
            prvsDomeProbeStts = "1"
            scan_selectString = scan_tempString
            sendData("frzprobe")
            default:
            scan_tempString = "resume_scanning"
            prvsDomeProbeStts = "3"
            scan_selectString = scan_tempString
            }
        
        }
    }
    
    // MARK: - CBCentralManagerDelegate methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) // Invoked when the central manager’s state is updated.
    {
        USBChrgButton.isHidden = true
        RSSIButton.isHidden = true
      
        domeChartButton.isHidden = true
        probeChartButton.isHidden = true
        probeAlrmValueDsply.isHidden = true
        setTempAlrmBttn.isHidden = true

        var message = ""

        _ = false

        switch central.state {
        case .poweredOff:   message = "Bluetooth on this device is currently powered off."
        case .unsupported:  message = "This device does not support Bluetooth Low Energy."
        case .unauthorized: message = "This app is not authorized to use Bluetooth Low Energy."
        case .resetting:    message = "The BLE Manager is resetting; a state update is pending."
        case .unknown:      message = "The state of the BLE Manager is unknown."
        case .poweredOn:
            
            message = "Bluetooth LE is turned on and ready for communication."
            print(message)
            centralManager.scanForPeripherals(withServices: nil, options: nil) // Option 1: Scan for all devices
            // Option 2: Scan for devices that have the service you're interested in...
            //let sensorTagAdvertisingUUID = CBUUID(string: Device.SensorTagAdvertisingUUID)
            //print("Scanning for EggZact adverstising with UUID: \(sensorTagAdvertisingUUID)")
            //centralManager.scanForPeripheralsWithServices([sensorTagAdvertisingUUID], options: nil)
            //centralManager.scanForPeripherals(withServices: [sensorTagAdvertisingUUID], options: nil)
        @unknown default:
            message = "Bluetooth LE Central Manage placeholder for any future response received"
            
        }
/*
        if showAlert
        {
            let alertController = UIAlertController(title: "Central Manager State", message: message, preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil)
            alertController.addAction(okAction)
            self.show(alertController, sender: self)
        }
 */
    }
    
    /*
     Invoked when the central manager discovers a peripheral while scanning.
     
     The advertisement data can be accessed through the keys listed in Advertisement Data Retrieval Keys.
     You must retain a local copy of the peripheral if any command is to be performed on it.
     In use cases where it makes sense for your app to automatically connect to a peripheral that is
     located within a certain range, you can use RSSI data to determine the proximity of a discovered
     peripheral device.
     
     central - The central manager providing the update.
     peripheral - The discovered peripheral.
     advertisementData - A dictionary containing any advertisement data.
     RSSI - The current received signal strength indicator (RSSI) of the peripheral, in decibels.
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"")
        
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
           // domeChartButton.isEnabled = false
            
            if peripheralName == "EggZact Dome Temp"
            {
                connectCounter = 0
                connectTimer = Timer.scheduledTimer(timeInterval:  1.0, target: self, selector: #selector(flashForConnect), userInfo: nil, repeats: true)
                print("EggZact Server found! Press Connect to Add!!")
                EggZact = peripheral // save a reference to the sensor tag
                EggZact!.delegate = self
                centralManager.stopScan()
                if didTapDisconnect
                {
                    didTapDisconnect = false
                }
                else
                {
                    //centralManager.connect(EggZact!, options: nil)
                }
                //settingsButton.isHidden   = false
            }
            else if peripheralName == "GrillSentry"
            {
                connectCounter = 0
                connectTimer = Timer.scheduledTimer(timeInterval:  1.0, target: self, selector: #selector(flashForConnect), userInfo: nil, repeats: true)
                print("GrillSentry Server found! Press Connect to Add!!")
                EggZact = peripheral // save a reference to the sensor tag
                EggZact!.delegate = self
                centralManager.stopScan()
            
                if didTapDisconnect
                {
                    didTapDisconnect = false
                }
                else
                {
                    //centralManager.connect(EggZact!, options: nil)
                }
                //settingsButton.isHidden   = false
            }
        }
    }
    
    /*
     Invoked when a connection is successfully created with a peripheral.
     
     This method is invoked when a call to connectPeripheral:options: is successful.
     You typically implement this method to set the peripheral’s delegate and to discover its services.
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("**** SUCCESSFULLY CONNECTED TO GrillSentry Thermometer !")
        
        // Now that we've successfully connected to the SensorTag, let's discover the services.
        // - NOTE:  we pass nil here to request ALL services be discovered.
        //          If there was a subset of services we were interested in, we could pass the UUIDs here.
        //          Doing so saves battery life and saves time.
        
        alreadyConnected = true
        Command.text = "Connected"
        peripheral.discoverServices(nil)
        connectTimer?.invalidate()
 
        versionTimer = Timer.scheduledTimer(timeInterval:  1.0, target: self, selector: #selector(pingforVersion), userInfo: nil, repeats: false)
        
        flashBlueLEDTimer = Timer.scheduledTimer(timeInterval:  0.75, target: self, selector: #selector(flashBlueLED), userInfo: nil, repeats: true)
    }
    
    /*
     Invoked when the central manager fails to create a connection with a peripheral.
     
     This method is invoked when a connection initiated via the connectPeripheral:options: method fails to complete.
     Because connection attempts do not time out, a failed connection usually indicates a transient issue,
     in which case you may attempt to connect to the peripheral again.
     */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    {
        print("**** CONNECTION TO SENSOR TAG FAILED!!!")
    }
    
    /*
     Invoked when an existing connection with a peripheral is torn down.
     
     This method is invoked when a peripheral connected via the connectPeripheral:options: method is disconnected.
     If the disconnection was not initiated by cancelPeripheralConnection:, the cause is detailed in error.
     After this method is called, no more methods are invoked on the peripheral device’s CBPeripheralDelegate object.
     
     Note that when a peripheral is disconnected, all of its services, characteristics, and characteristic descriptors are invalidated.
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("**** DISCONNECTED FROM EggZact/GrillSentry !!!")
        if error != nil {
            print("****** DISCONNECTION DETAILS: \(error!.localizedDescription)")
        }
    /*
        EggZact = nil
         centralManager.scanForPeripherals(withServices: nil, options: nil)
        do {
            sleep(3)        // 4 seconds for changing scan status
        }
    exit(0)
 */
 
        /*iCloud Writing - working and stubbed for futre implementation
     
        let probeTempvsTimeFileURL = setFileToDocumentsFolder(nameForFile: "ProbeTempvsTime", extForFile: "txt")
        let domeTempvsTimeFileURL = setFileToDocumentsFolder(nameForFile: "DomeTempvsTime", extForFile: "txt")
        
        let domeChartRecord = CKRecord(recordType: "GrillSentryCharts")  // Record Type on Icloud
        domeChartRecord["numberofChartMembers"] =  domefileEntryTotalCount as CKRecordValue
        domeChartRecord["durationofChart"] = domechartSecondCnt as CKRecordValue
        
        let domeChartAsset = CKAsset(fileURL: domeTempvsTimeFileURL)
        let probeChartAsset = CKAsset(fileURL: probeTempvsTimeFileURL)
        print("domeChartAsset \(domeTempvsTimeFileURL)")
        print("domeChartAsset \(probeTempvsTimeFileURL)")
        domeChartRecord["Dome_TempvsTime"] = domeChartAsset
        domeChartRecord["Probe_TempvsTime"] = probeChartAsset
     
        CKContainer.default().publicCloudDatabase.save(domeChartRecord) { [unowned self] record, error in DispatchQueue.main.async {
            if let error = error {
               // self.PHYStatusString1 = "Error" //: \(error.localizedDescription)"
                print("ICLOUD WRITE ERROR: \(error.localizedDescription)")
                }
            else { print("OK Writing to Cloud \(String(describing: domeChartAsset.fileURL))")
               ViewController.isDirty = true
                }
            }
     */
        
     // this code below added Jan2022 to correct BLE weak RF signal disconnect then "Tap to Connect" will not re-connect problem
    
        if let EggZact = self.EggZact
        {
            
            centralManager.cancelPeripheralConnection(EggZact) // From your app’s perspective the peripheral is considered disconnected. centralManager:didDisconnectPeripheral is called
            //centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
        
        EggZact = nil
        Command.textColor = UIColor.green
        Command.text = "Disconnect"
        alreadyConnected = false
        settingsButton.isHidden = true
        batteryButton.isHidden  = true
        USBChrgButton.isHidden = true
        RSSIButton.isHidden = true
        RSSILabel.isHidden = true
        domeChartButton.isHidden = true
        probeChartButton.isHidden = true

        stopProbeTempAlrmBttn.isHidden = true
        stopDomeTempAlrmBttn.isHidden = true
        setTempAlrmBttn.isHidden = true
        
        domeAlrmValueDsply.isHidden = true
        probeAlrmValueDsply.isHidden = true
        
        domeTimer?.invalidate()
        probeTimer?.invalidate()
        batteryTimer?.invalidate()
    
    // this code above added Jan2022 to correct the BLE weak RF signal disconnect then "Tap to Connect" will not re-connect problem
        
        flashBlueLEDTimer?.invalidate()
        blueLED.isHidden = true
        centralManager.scanForPeripherals(withServices: nil, options: nil)     //  exit(0)

    }
    
    //MARK: - CBPeripheralDelegate methods
    
    /*
     Invoked when you discover the peripheral’s available services.
     
     This method is invoked when your app calls the discoverServices: method.
     If the services of the peripheral are successfully discovered, you can access them
     through the peripheral’s services property.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    // When the specified services are discovered, the peripheral calls the peripheral:didDiscoverServices: method of its delegate object.
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        if error != nil
        {
            print("ERROR DISCOVERING SERVICES: \(String(describing: error?.localizedDescription))")
            return
        }
        
        if let services = peripheral.services
        {
            for service in services // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
            {
                print("Discovered service \(service)")
                if (service.uuid == CBUUID(string: Device.TemperatureServiceUUID)) || (service.uuid == CBUUID(string: Device.HumidityServiceUUID))
                {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    /* Invoked when you discover the characteristics of a specified service.
     If the characteristics of the specified service are successfully discovered, you can access them through the service's characteristics property. */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        if error != nil
        {
            print("ERROR DISCOVERING CHARACTERISTICS: \(String(describing: error?.localizedDescription))")
            return
        }
        
        if let characteristics = service.characteristics
        {
            for characteristic in characteristics
            {
                if characteristic.uuid == CBUUID(string: Device.TemperatureDataUUID)
                {
                    sendbuffer = characteristic
                    EggZact?.setNotifyValue(true, for: characteristic)
       //             let bytes : [UInt8] = [ 0x54, 0x45, 0x4D, 0x50, 0x4F, 0x4E, 0x0d ]  // TempOn
       //             let data = NSData(bytes: bytes, length: bytes.count)
       //             EggZact?.writeValue(data as Data, for: characteristic, type: .withResponse)
               
                }
            }
        }
    }
    
    /* Invoked when you retrieve a specified characteristic’s value, or when the peripheral device notifies your app that the characteristic’s value has changed.
     This method is invoked when your app calls the readValueForCharacteristic: method,
     or when the peripheral notifies your app that the value of the characteristic for which notifications and indications are enabled has changed. */
    internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        // CBCharacteristicPropertyIndicate KS
        if error != nil
        {
            print("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))")
            return
        }
        
        if let dataBytes = characteristic.value // extract the data from the characteristic's value property and display the value based on the characteristic type
        {
            if characteristic.uuid == CBUUID(string: Device.TemperatureDataUUID)
            {
                tempSecCaptureCnt += 1  //server response timebase counter
                var tempString = ""
                var ProbeTempString = ""
                var DomeTempString = ""
                if let dataString = String(data: dataBytes, encoding: String.Encoding.utf8)
                {
                    tempString = dataString
                    tempString = tempString.replacingOccurrences(of: "\n", with: "")
                    tempString = tempString.replacingOccurrences(of: "\r", with: "")
                    tempString = tempString.replacingOccurrences(of: "\0", with: "")
                    
                    if tempString.hasPrefix("00")
                    {
                        tempString.remove(at: tempString.startIndex)
                        tempString.remove(at: tempString.startIndex)
                    }
                }
                print("receivd from TC data \(tempString)")
                if (tempString.contains("H")) {// check the server HWv Gen2, Gen2.5, or Gen3 ?
                versionString     = ("Server: \(tempString)")
//              clientVersionString = ("Client: G3_v1.0")
                clientVersionString = ("Client: G3_Charts_v3.0")
                    
                if (tempString.contains("G20120")) {
                    if(serverattachedString == "Gen20120") {
                        
                    }
                    else
                    {
                    serverattachedString = "Gen20120"
                        setTempAlrmBttn.isHidden = false
                    domeTimer     = Timer.scheduledTimer(timeInterval:  1.0, target: self, selector: #selector(pingforDome),    userInfo: nil, repeats: true)
                    batteryTimer = Timer.scheduledTimer(timeInterval: 1.4, target: self, selector: #selector(pingForBattery), userInfo: nil, repeats: true)
                    }
                }
                if (tempString.contains("H2G2.5")) {
                    serverattachedString = "Gen2.5"
                    setTempAlrmBttn.isHidden = false
                }
                if (tempString.contains("H5.2")) {
                    serverattachedString = "Gen3.0"
                    setTempAlrmBttn.isHidden = false
                }
                }
                if (tempString.contains("T")) {//this routine run by RTD and Thermocouple
                domeChartButton.isHidden = false
                probeChartButton.isHidden = true
                    if (serverattachedString == "Gen20120") {
                       
                        
                        var unit2 = ""
                        var DomeTempFloat = 0.0
                        var domeTmpInt: Int = 0
                        //   let countup = 0
                            
                        let DomeTemp = tempString.prefix(5);
                        DomeTempString = String(DomeTemp)
                        if DomeTempString.hasPrefix("0")
                        {
                            DomeTempString.remove(at: DomeTempString.startIndex)
                        }
                        print("String from server(-probe: \(tempString)")
                        print("GrillSentryDomeTemp: \(DomeTempString)")
                        print("the dome key counters cnt1:  \(tempSecCaptureCnt1)")

                        domeAlrmValueDsply.textAlignment = NSTextAlignment.right
                        domeAlrmValueDsply.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 16  )
                        domeAlrmValueDsply.minimumScaleFactor = 0.0001
            
                        domeAlrmValueDsply.backgroundColor = UIColor.clear
                        domeAlrmValueDsply.textColor = UIColor.green
                        if domeAlrmIsArmd {
                            let degFforProbePacket = "°F"
                            domeAlrmValueDsply.isHidden = false
                            domeAlrmValueDsply.text = String("DomeAlrm = \(domeAlrmTmpInt + 1)") + degFforProbePacket
                        }
                        else
                        {
                            
                            domeAlrmValueDsply.isHidden = true
                            domeAlrmValueDsply.text = String("DomeAlrm = \(domeAlrmTmpInt + 1)")
                        }
                  
                        DomeTempFloat = Double(Float(DomeTempString) ?? 0)
                        domeTmpInt = Int(DomeTempFloat)
                      
                        // Determimne if the Dome Temp Alarm has been exceeded
                        // initiate the audio alarm
                        if ((domeTmpInt > domeAlrmTmpInt) && domeAlrmIsArmd) {
                        
                            if let audioPlayer = audioPlayer, audioPlayer.isPlaying
                            {
                                print ("we think the audio player is playing")
                                // but alarm temp level has been reached
                            }
                            else
                                {
                                    guard let pathToSound = Bundle.main.path(forResource: "GrillDomeAlarm", ofType: "mp3") else { return }
                                    let url = URL(fileURLWithPath: pathToSound)
                                do {
                                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                                    audioPlayer?.play()
                                    stopDomeTempAlrmBttn.isHidden = false
                               
                                    }
                                    catch {
                                    print ("something went wromg with auduio player")
                                }
                                print ("you passed the alarm temp \(domeAlrmTmpInt)")
                            }
                        }
                        else
                        {
                            stopDomeTempAlrmBttn.isHidden = true
                        }
                    //only write the Dome Temp to file every 10th reading (or each 10 second interval)
                        var DomeTempString2 = DomeTempString    // save away for Charting only before degC conversiuon
                        if (!isCelcius) {
                            unit2 = "°F"
                        }
                        
                        if (isCelcius) {
                  
                        unit2 = "°C"
                        degFforProbePacket = "C"
                        DomeTempString = String(format: "%.1f", DomeTempFloat)
                        }
                    //
                        if(domefileEntryCounter == (domeCaptureDivider-1) && domefileEntryTotalCount < domeCaptureTotalCnt)
                        {
                            let dateTimeString = getDateTime()
                             
                            var DomeTempFloat2 = Float(DomeTempString2)!
                            DomeTempFloat2 = round(DomeTempFloat2 * 10) / 10.0
                            DomeTempString2 = String(format: "%.1f", DomeTempFloat2)
                            
                            if tempSecCaptureCnt1 > 1
                            {
                                let domeTempArrayString = domeTempArray[(Int(tempSecCaptureCnt1)-1)]
                                let domeTempArrayFloat = Float(domeTempArrayString) ?? 0.0

                                if DomeTempFloat2 > (domeTempArrayFloat + 150)
                                {
                                 DomeTempString2 = domeTempArray[(Int(tempSecCaptureCnt1)-1)]
                                }
                                
                                if (DomeTempFloat2 < domeTempArrayFloat - 150)
                                {
                                 DomeTempString2 = domeTempArray[(Int(tempSecCaptureCnt1)-1)]
                                }
                            }
 
                            let DomeTempTxt = DomeTempString2   // save for charts
                            domeTempArray.append(DomeTempTxt)  // dome temp data array
                           
                            if ((tempSecCaptureCnt1 % Int32(domeChrtSamplePerMinInt)) == 0)
                            {
                                DomeTempvsTimeString = (DomeTempvsTimeString + "Date+Time," + dateTimeString + ", DomeTemp," + " \(DomeTempTxt)" + ",\(unit2)\n")
                               
                                do {
                                //Write to file
                                try DomeTempvsTimeString.write(to: setFileToDocumentsFolder(nameForFile: "DomeTempvsTime", extForFile: "txt"), atomically: true, encoding: String.Encoding.utf8)
                                    } catch let error as NSError { print("failed to write to URL")
                                        print(error.localizedDescription)
                                    }
                            }
                                domefileEntryCounter = 0;
                                domefileEntryTotalCount += 1;   //
                                domechartSecondCnt.append(tempSecCaptureCnt)
                                domechartMinuteCnt.append(tempSecCaptureCnt/60)
                            }
                            else
                            {
                                if domefileEntryTotalCount < domeCaptureTotalCnt
                                {
                                domefileEntryCounter += 1
                                }
                                else
                                {   //we've captured all the Chart Data points
                                    domefileEntryCounter = 0
                                }
                            }
                        
                            tempSecCaptureCnt1 += 1 // sample rate = 0.5/sec so multiply by 2 to get on use for Dome File Entry
                            
                            switch scan_selectString {
                            
                            case "resume_scanning":
                                Command.textColor = UIColor.green
                                Command.text = String("\(DomeTempString)" + unit2) //did not send deg indicator in 2019
                            case "scan_dome_only":
                                Command.textColor = UIColor.green
                                Command.text = String("\(DomeTempString)" + unit2)
                            default:
                                scan_tempString = "resume_scanning"
                            }
                    }
                    if (serverattachedString == "Gen3.0") {
                    
                    var unit2 = ""
                    var DomeTempFloat = 0.0
                    var domeTmpInt: Int = 0
                    //   let countup = 0
                        
                    let DomeTemp = tempString.prefix(5);
                    DomeTempString = String(DomeTemp)
                    if DomeTempString.hasPrefix("0")
                    {
                        DomeTempString.remove(at: DomeTempString.startIndex)
                    }
                    print("String from server(-probe: \(tempString)")
                    print("GrillSentryDomeTemp: \(DomeTempString)")
                    print("the dome key counters cnt1:  \(tempSecCaptureCnt1)")

                    domeAlrmValueDsply.textAlignment = NSTextAlignment.right
                    domeAlrmValueDsply.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 16  )
                    domeAlrmValueDsply.minimumScaleFactor = 0.0001
        
                    domeAlrmValueDsply.backgroundColor = UIColor.clear
                    domeAlrmValueDsply.textColor = UIColor.green
                    if domeAlrmIsArmd {
                        let degFforProbePacket = "°F"
                        domeAlrmValueDsply.isHidden = false
                        domeAlrmValueDsply.text = String("DomeAlrm = \(domeAlrmTmpInt + 1)") + degFforProbePacket
                    }
                    else
                    {
                        domeAlrmValueDsply.isHidden = true
                        domeAlrmValueDsply.text = String("DomeAlrm = \(domeAlrmTmpInt + 1)")
                    }
              
                    DomeTempFloat = Double(Float(DomeTempString) ?? 0)
                    domeTmpInt = Int(DomeTempFloat)
                  
                    // Determimne if the Dome Temp Alarm has been exceeded
                    // initiate the audio alarm
                    if ((domeTmpInt > domeAlrmTmpInt) && domeAlrmIsArmd) {
                    
                        if let audioPlayer = audioPlayer, audioPlayer.isPlaying
                        {
                            print ("we think the audio player is playing")
                            // but alarm temp level has been reached
                        }
                        else
                            {
                                guard let pathToSound = Bundle.main.path(forResource: "GrillDomeAlarm", ofType: "mp3") else { return }
                                let url = URL(fileURLWithPath: pathToSound)
                            do {
                                audioPlayer = try AVAudioPlayer(contentsOf: url)
                                audioPlayer?.play()
                                stopDomeTempAlrmBttn.isHidden = false
                           
                                }
                                catch {
                                print ("something went wromg with auduio player")
                            }
                            print ("you passed the alarm temp \(domeAlrmTmpInt)")
                        }
                    }
                    else
                    {
                        stopDomeTempAlrmBttn.isHidden = true
                    }
                //only write the Dome Temp to file every 10th reading (or each 10 second interval)
                    var DomeTempString2 = DomeTempString    // save away for Charting only before degC conversiuon

                    if (tempString.contains("F")) {
                    unit2 = "°F"
                    degFforProbePacket = "F"
                    // print("Degree F")
                    }
                      
                    if (tempString.contains("C")) {
                    unit2 = "°C"
                    degFforProbePacket = "C"
                    //  print("Degree C")
                    DomeTempFloat = Double(DomeTempString)!
                    DomeTempFloat -= 32.0
                    DomeTempFloat *= 0.55555
                    DomeTempString = String(format: "%.1f", DomeTempFloat)
                    }
                    
                    if(domefileEntryCounter == (domeCaptureDivider-1) && domefileEntryTotalCount < domeCaptureTotalCnt)
                    {
                        let dateTimeString = getDateTime()
                         
                        var DomeTempFloat2 = Float(DomeTempString2)!
                        DomeTempFloat2 = round(DomeTempFloat2 * 10) / 10.0
                        DomeTempString2 = String(format: "%.1f", DomeTempFloat2)
                        
                        if tempSecCaptureCnt1 > 1  {     // simple filter to eliminate momentary open RTD circuit conditions
                           let domeTempArrayString = domeTempArray[(Int(tempSecCaptureCnt1)-1)]
                            let domeTempArrayFloat = Float(domeTempArrayString) ?? 0.0

                            if (DomeTempFloat2 > (domeTempArrayFloat + 150))
                            {
                             DomeTempString2 = domeTempArray[(Int(tempSecCaptureCnt1)-1)]
                            }
                             if (DomeTempFloat2 < (domeTempArrayFloat - 150))
                            {
                             DomeTempString2 = domeTempArray[(Int(tempSecCaptureCnt1)-1)]
                            }
                        }
                        
                        let DomeTempTxt = DomeTempString2   // save for charts
                        domeTempArray.append(DomeTempTxt)  // dome temp data array
                       
                        if ((tempSecCaptureCnt1 % Int32(domeChrtSamplePerMinInt)) == 0)
                        {
                            DomeTempvsTimeString = (DomeTempvsTimeString + "Date+Time," + dateTimeString + ", DomeTemp," + " \(DomeTempTxt)" + ",\(unit2)\n")
                            
                           //  Write the DomeTemp and the capture time to a text file
                          
                            do {
                            //Write to file
                            try DomeTempvsTimeString.write(to: setFileToDocumentsFolder(nameForFile: "DomeTempvsTime", extForFile: "txt"), atomically: true, encoding: String.Encoding.utf8)
                                } catch let error as NSError { print("failed to write to URL")
                                    print(error.localizedDescription)
                                }
                             
                        }
                          
                            domefileEntryCounter = 0;
                            domefileEntryTotalCount += 1;   //
                            domechartSecondCnt.append(tempSecCaptureCnt)
                            domechartMinuteCnt.append(tempSecCaptureCnt/60)
                        }
                        else
                        {
                            if domefileEntryTotalCount < domeCaptureTotalCnt
                            {
                            domefileEntryCounter += 1
                            }
                            else
                            {   //we've captured all the Chart Data points
                                domefileEntryCounter = 0
                            }
                        }
                        //Start the file capture for Graphs
                        tempSecCaptureCnt1 += 1 // sample rate = 0.5/sec so multiply by 2 to get on use for Dome File Entry

                        switch scan_selectString {
                        case "resume_scanning":
                            Command.textColor = UIColor.green
                            Command.text = (DomeTempString + unit2)
                        case "scan_dome_only":
                            Command.textColor = UIColor.green
                            Command.text = (DomeTempString  + unit2)
                        default:
                            scan_tempString = "resume_scanning"
                        }
                    if (tempString.contains("Z")) {
                        scan_selectString = "resume_scanning"
                        domeChartButton.isHidden = false
                        probeChartButton.isHidden = false
                    
                    }
                    if (tempString.contains("X")) {
                        scan_selectString = "scan_probe_only"
                        domeChartButton.isHidden = false
                        probeChartButton.isHidden = false
                      
                    }
                    if (tempString.contains("W")) {
                        scan_selectString = "scan_dome_only"
                        domeChartButton.isHidden = false
                        probeChartButton.isHidden = false
                      
                    }
                    if (tempString.contains("Q")) {
                        scan_selectString = "resume_scanning"
                        probeAttached = false // "Q" indicates no food probe attached
                        probeChartButton.isHidden = true
                        probeAlrmValueDsply.isHidden = true
                    }
                    if (tempString.contains("Y")) {
                        //"Y" for USB chrg connected
                        USBChrgButton.isHidden = false
                    }
                    if (tempString.contains("N")) {
                        //"N" for USB charge disconnected
                        USBChrgButton.isHidden = true
                    }
                    if (tempString.contains("S")) {// is this the RSSI Server Value string version ?
                
                        let distance = tempString.firstIndex(of: "S")!;
                        let Sindex = tempString.distance(from: tempString.startIndex, to: distance)
                        
                        RSSIButton.isHidden = false
                            
                        let RSSIString = tempString;
                        let start = RSSIString.index(RSSIString.startIndex, offsetBy: (Sindex+1));
                        let end = RSSIString.index(RSSIString.startIndex, offsetBy: (Sindex+4));
                        let range = start..<end;
                        
                        let RSSIString2 = RSSIString[range];
                        print("RSSI Server Value: \(RSSIString2)")
                        
                        RSSILabel.isHidden = false
                        RSSILabel.text = ("Signal = \(RSSIString2)")
                
                        RSSIInteger = Int(RSSIString2)!
                
                            if (RSSIInteger >= 200 )
                            {
                                RSSIButton.setImage(UIImage(named: "RSSI_100v4.png"), for: UIControl.State.normal)
                            }
                            else if (RSSIInteger >= 190 )
                            {
                                RSSIButton.setImage(UIImage(named: "RSSI_080v3.png"), for: UIControl.State.normal)
                            }
                            else if (RSSIInteger >= 180)
                            {
                                RSSIButton.setImage(UIImage(named: "RSSI_060v3.png"), for: UIControl.State.normal)
                            }
                            else if (RSSIInteger >= 170)
                            {
                                RSSIButton.setImage(UIImage(named: "RSSI_040v3.png"), for: UIControl.State.normal)
                            }
                            else if (RSSIInteger >= 165)
                            {
                                RSSIButton.setImage(UIImage(named: "RSSI_020v3.png"), for: UIControl.State.normal)
                            }
                            else if (RSSIInteger >= 155)
                            {
                                RSSIButton.setImage(UIImage(named: "RSSI_000v3.png"), for: UIControl.State.normal)
                            }
                        
                    }
                    if (tempString.contains("B")) { // is this the battery voltage value string?
                        batteryButton.isHidden = false
                        setTempAlrmBttn.isHidden = false
                        let distance = tempString.firstIndex(of: "B")!;
                        let Bindex = tempString.distance(from: tempString.startIndex, to: distance);
                        
                        let batteryString = String(tempString)
                        
                        let start = batteryString.index(batteryString.startIndex, offsetBy: (Bindex+1));
                        let end = batteryString.index(batteryString.startIndex, offsetBy: (Bindex+4));
                        let range = start..<end;
                        // let battery = tempString.suffix(10);
                        let batteryString2 = String(batteryString[range]);
                        
                        print("index of Battery: \(Bindex)")
                    
                        battVoltage = Double(batteryString2)!
                        
                        print("Battery voltage String: \(batteryString2)")
                        
                        batteryString3 = "Battery Voltage = \(batteryString2)V"
                        
                        if (battVoltage >= 3.9)
                        {
                            batteryButton.setImage(UIImage(named: "battery100.png"), for: UIControl.State.normal)
                        }
                        else if (battVoltage >= 3.7)
                        {
                            batteryButton.setImage(UIImage(named: "battery080.png"), for: UIControl.State.normal)
                        }
                        else if (battVoltage >= 3.5)
                        {
                            batteryButton.setImage(UIImage(named: "battery060.png"), for: UIControl.State.normal)
                        }
                        else if (battVoltage >= 3.4)
                        {
                            batteryButton.setImage(UIImage(named: "battery040.png"), for: UIControl.State.normal)
                        }
                        else if (battVoltage >= 3.3)
                        {
                            batteryButton.setImage(UIImage(named: "battery020.png"), for: UIControl.State.normal)
                        }
                        else
                        {
                            batteryButton.setImage(UIImage(named: "battery000.png"), for: UIControl.State.normal)
                        }
                        if (battVoltage <= 3.2) // in order to have the temperature blink to inform the user that the battery is low
                        {
                            UIView.animate(withDuration: 0.5, delay: 0.5, options: UIView.AnimationOptions.curveEaseOut, animations:
                                {
                                    self.Command.alpha = 0.0
                                }, completion: nil)
                
                            UIView.animate(withDuration: 0.5, delay: 0.5, options: UIView.AnimationOptions.curveEaseOut, animations:
                                {
                                        self.Command.alpha = 1.0
                                }, completion: nil)
                        }
                    }
                }
                    if (serverattachedString == "Gen2.5") {
                        //Start the file capture for Graphs
                        var unit2 = ""
                        var DomeTempFloat = 0.0
                        var domeTmpInt: Int = 0
                        //   let countup = 0
                            
                        let DomeTemp = tempString.prefix(5);
                        DomeTempString = String(DomeTemp)
                        if DomeTempString.hasPrefix("0")
                        {
                            DomeTempString.remove(at: DomeTempString.startIndex)
                        }
                        print("String from server(-probe: \(tempString)")
                        print("GrillSentryDomeTemp: \(DomeTempString)")
                        print("the dome key counters cnt1:  \(tempSecCaptureCnt1)")

                        domeAlrmValueDsply.textAlignment = NSTextAlignment.right
                        domeAlrmValueDsply.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 16  )
                        domeAlrmValueDsply.minimumScaleFactor = 0.0001
            
                        domeAlrmValueDsply.backgroundColor = UIColor.clear
                        domeAlrmValueDsply.textColor = UIColor.green
                        if domeAlrmIsArmd {
                            let degFforProbePacket = "°F"
                            domeAlrmValueDsply.isHidden = false
                            domeAlrmValueDsply.text = String("DomeAlrm = \(domeAlrmTmpInt + 1)") + degFforProbePacket
                        }
                        else
                        {
                            domeAlrmValueDsply.isHidden = true
                            domeAlrmValueDsply.text = String("DomeAlrm = \(domeAlrmTmpInt + 1)")
                        }
                  
                        DomeTempFloat = Double(Float(DomeTempString) ?? 0)
                        domeTmpInt = Int(DomeTempFloat)
                      
                        // Determimne if the Dome Temp Alarm has been exceeded
                        // initiate the audio alarm
                        if ((domeTmpInt > domeAlrmTmpInt) && domeAlrmIsArmd) {
                        
                            if let audioPlayer = audioPlayer, audioPlayer.isPlaying
                            {
                                print ("we think the audio player is playing")
                                // but alarm temp level has been reached
                            }
                            else
                                {
                                    guard let pathToSound = Bundle.main.path(forResource: "GrillDomeAlarm", ofType: "mp3") else { return }
                                    let url = URL(fileURLWithPath: pathToSound)
                                do {
                                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                                    audioPlayer?.play()
                                    stopDomeTempAlrmBttn.isHidden = false
                               
                                    }
                                    catch {
                                    print ("something went wromg with auduio player")
                                }
                                print ("you passed the alarm temp \(domeAlrmTmpInt)")
                            }
                        }
                        else
                        {
                            stopDomeTempAlrmBttn.isHidden = true
                        }
                    //only write the Dome Temp to file every 10th reading (or each 10 second interval)
                        var DomeTempString2 = DomeTempString    // save away for Charting only before degC conversiuon

                        if (tempString.contains("F")) {
                        unit2 = "°F"
                        degFforProbePacket = "F"
                        // print("Degree F")
                        }
                          
                        if (tempString.contains("C")) {
                        unit2 = "°C"
                        degFforProbePacket = "C"
                        //  print("Degree C")
                        DomeTempFloat = Double(DomeTempString)!
                        DomeTempFloat -= 32.0
                        DomeTempFloat *= 0.55555
                        DomeTempString = String(format: "%.1f", DomeTempFloat)
                        }
                    
                        
                        if(domefileEntryCounter == (domeCaptureDivider-1) && domefileEntryTotalCount < domeCaptureTotalCnt)
                        {
                            let dateTimeString = getDateTime()
                             
                            var DomeTempFloat2 = Float(DomeTempString2)!
                            DomeTempFloat2 = round(DomeTempFloat2 * 10) / 10.0
                            DomeTempString2 = String(format: "%.1f", DomeTempFloat2)
                      
                            if tempSecCaptureCnt1 > 1  {     // simple filter to eliminate momentary open thermocouple circuit conditions
                               let domeTempArrayString = domeTempArray[(Int(tempSecCaptureCnt1)-1)]
                                let domeTempArrayFloat = Float(domeTempArrayString) ?? 0.0

                                if (DomeTempFloat2 > (domeTempArrayFloat + 150))
                                {
                                 DomeTempString2 = domeTempArray[(Int(tempSecCaptureCnt1)-1)]
                                }
                                
                                if (DomeTempFloat2 < (domeTempArrayFloat - 150))
                                {
                                 DomeTempString2 = domeTempArray[(Int(tempSecCaptureCnt1)-1)]
                                }
                            }
                            
                            let DomeTempTxt = DomeTempString2   // save for charts
                            domeTempArray.append(DomeTempTxt)  // dome temp data array
                           
                            if ((tempSecCaptureCnt1 % Int32(domeChrtSamplePerMinInt)) == 0)
                            {
                                DomeTempvsTimeString = (DomeTempvsTimeString + "Date+Time," + dateTimeString + ", DomeTemp," + " \(DomeTempTxt)" + ",\(unit2)\n")
                               //  Write the DomeTemp and the capture time to a text file
                              //  let domeTempvsTimeFileURL = getDocumentsDirectory().appendingPathComponent("DomeTempvsTime.txt")
                                do {
                                //Write to file
                                try DomeTempvsTimeString.write(to: setFileToDocumentsFolder(nameForFile: "DomeTempvsTime", extForFile: "txt"), atomically: true, encoding: String.Encoding.utf8)
                                    } catch let error as NSError { print("failed to write to URL")
                                        print(error.localizedDescription)
                                    }
                                 
                            }
                               
                                domefileEntryCounter = 0;
                                domefileEntryTotalCount += 1;   //
                                domechartSecondCnt.append(tempSecCaptureCnt)
                                domechartMinuteCnt.append(tempSecCaptureCnt/60)
                              
                            }
                            else
                            {
                                if domefileEntryTotalCount < domeCaptureTotalCnt
                                {
                                domefileEntryCounter += 1
                                }
                                else
                                {   //we've captured all the Chart Data points
                                    domefileEntryCounter = 0
                                }
                            }
                          
                        tempSecCaptureCnt1 += 1 // sample rate = 0.5/sec so multiply by 2 to get on use for Dome File Entry
            
                        switch scan_selectString {
            
                        case "resume_scanning":
                            Command.textColor = UIColor.green
                            Command.text = (DomeTempString + unit2)
                        case "scan_dome_only":
                            Command.textColor = UIColor.green
                            Command.text = (DomeTempString  + unit2)
                        default:
                            scan_tempString = "resume_scanning"
            }
            if (tempString.contains("Z")) {
                scan_selectString = "resume_scanning"
            
                domeChartButton.isHidden = false
                probeChartButton.isHidden = false
                
            }
            if (tempString.contains("X")) {
                scan_selectString = "scan_probe_only"
            
                domeChartButton.isHidden = false
                probeChartButton.isHidden = false
                
            }
            if (tempString.contains("W")) {
                scan_selectString = "scan_dome_only"
            
                domeChartButton.isHidden = false
                probeChartButton.isHidden = false
                
            }
            if (tempString.contains("Q")) {
                scan_selectString = "resume_scanning"
                probeChartButton.isHidden = true
                
            }
            if (tempString.contains("Y")) {
                //"Y" for USB chrg connected
                USBChrgButton.isHidden = false
            }
            if (tempString.contains("N")) {
                //"N" for USB charge disconnected
                USBChrgButton.isHidden = true
            }
            if (tempString.contains("S")) {// is this the RSSI Server Value string version ?
                let distance = tempString.firstIndex(of: "S")!;
                let Sindex = tempString.distance(from: tempString.startIndex, to: distance)
    
                print("received string from server \(tempString)")
                print("index of S: \(Sindex)")
                
                RSSIButton.isHidden = false
            
                let RSSIString = tempString;

                let start = RSSIString.index(RSSIString.startIndex, offsetBy: (Sindex+1));
                let end = RSSIString.index(RSSIString.startIndex, offsetBy: (Sindex+4));
                let range = start..<end;
                
                let RSSIString2 = RSSIString[range];

                print("RSSI Server Value: \(RSSIString2)")
                
                RSSILabel.isHidden = false
                RSSILabel.text = ("Signal = \(RSSIString2)")
        
                RSSIInteger = Int(RSSIString2)!
                //  RSSIString2 = ("RSSI = \(RSSIString2)")
        
                if (RSSIInteger >= 200 )
                {
                    RSSIButton.setImage(UIImage(named: "RSSI_100v4.png"), for: UIControl.State.normal)
                }
                else if (RSSIInteger >= 190 )
                {
                    RSSIButton.setImage(UIImage(named: "RSSI_080v3.png"), for: UIControl.State.normal)
                }
                else if (RSSIInteger >= 180)
                {
                    RSSIButton.setImage(UIImage(named: "RSSI_060v3.png"), for: UIControl.State.normal)
                }
                else if (RSSIInteger >= 170)
                {
                    RSSIButton.setImage(UIImage(named: "RSSI_040v3.png"), for: UIControl.State.normal)
                }
                else if (RSSIInteger >= 165)
                {
                    RSSIButton.setImage(UIImage(named: "RSSI_020v3.png"), for: UIControl.State.normal)
                }
                else if (RSSIInteger >= 155)
                {
                    RSSIButton.setImage(UIImage(named: "RSSI_000v3.png"), for: UIControl.State.normal)
                }
            }
            if (tempString.contains("B")) {   // is this the battery voltage value string?
    
        batteryButton.isHidden = false
        let distance = tempString.firstIndex(of: "B")!;
        let Bindex = tempString.distance(from: tempString.startIndex, to: distance)

        let batteryString = String(tempString)
        
        let start = batteryString.index(batteryString.startIndex, offsetBy: (Bindex+1));
        let end = batteryString.index(batteryString.startIndex, offsetBy: (Bindex+4));
        let range = start..<end;
        // let battery = tempString.suffix(10);
        let batteryString2 = String(batteryString[range]);
        print("index of Battery: \(Bindex)")
        battVoltage = Double(batteryString2)!
        print("Battery voltage String: \(batteryString2)")
        batteryString3 = "Battery Voltage = \(batteryString2)V"
        
        if (battVoltage >= 3.9)
        {
            batteryButton.setImage(UIImage(named: "battery100.png"), for: UIControl.State.normal)
        }
        else if (battVoltage >= 3.7)
        {
            batteryButton.setImage(UIImage(named: "battery080.png"), for: UIControl.State.normal)
        }
        else if (battVoltage >= 3.5)
        {
            batteryButton.setImage(UIImage(named: "battery060.png"), for: UIControl.State.normal)
        }
        else if (battVoltage >= 3.4)
        {
            batteryButton.setImage(UIImage(named: "battery040.png"), for: UIControl.State.normal)
        }
        else if (battVoltage >= 3.3)
        {
            batteryButton.setImage(UIImage(named: "battery020.png"), for: UIControl.State.normal)
        }
        else
        {
            batteryButton.setImage(UIImage(named: "battery000.png"), for: UIControl.State.normal)
        }
        if (battVoltage <= 3.2) // in order to have the temperature blink to inform the user that the battery is low
        {
            UIView.animate(withDuration: 0.5, delay: 0.5, options: UIView.AnimationOptions.curveEaseOut, animations:
                {
                                self.Command.alpha = 0.0
                }, completion: nil)

            UIView.animate(withDuration: 0.5, delay: 0.5, options: UIView.AnimationOptions.curveEaseOut, animations:
        {
            self.Command.alpha = 1.0
        }, completion: nil)
        }
    }
            }
                }
                if (tempString.contains("A")) {    // is this the PHYStatus String
                    var PHYStatusString2 = String(tempString)
                    PHYStatusString2 = PHYStatusString2.replacingOccurrences(of: "A", with: "", options:NSString.CompareOptions.literal, range: nil)
                        
                        PHYStatusString1 = ("PHY State = \(PHYStatusString2)")
                        
                        print("Encoded PHYSTATUS: \(tempString)\n")
                    }
                if (tempString.contains("P")) {// is the food probe connected ?
                    probeChartButton.isHidden = false
                    
                    print("the P in probe \(tempString)")
                    
                    print("the probe key counters cnt2:  \(tempSecCaptureCnt2)")
                    var probeTmpInt: Int = 0
                    
                    probeAttached = true    // yes the food probe is attached
                    let unit = isCelcius ? "°C" : "°F"
            
                    probeAlrmValueDsply.textAlignment = NSTextAlignment.right
                    probeAlrmValueDsply.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 16  )
                    probeAlrmValueDsply.backgroundColor = UIColor.clear
                    probeAlrmValueDsply.textColor = UIColor.white
                    
                    if probeAlrmIsArmd
                        {
                        let degFforProbePacket = "°F"
                        probeAlrmValueDsply.isHidden = false
                        probeAlrmValueDsply.text = String("ProbeAlrm = \(probeAlrmTmpInt + 1)") + degFforProbePacket
                        }
                    else
                        {
                            probeAlrmValueDsply.isHidden = true
                        }
                                    
                    var ProbeTemp = tempString.prefix(3);
                    ProbeTempString = String(ProbeTemp)
                    if ProbeTempString.hasPrefix("0")
                        {
                            ProbeTemp.remove(at: ProbeTempString.startIndex)
                        }
                    
                    probeTmpInt = Int(ProbeTempString) ?? 0
            
                    if probeTmpInt > 250
                    { //probeTmpInt = 250
                        UIView.animate(withDuration: 0.5, delay: 0.5, options: UIView.AnimationOptions.curveEaseOut, animations:
                                        {
                                            self.Command.alpha = 0.0
                                        }, completion: nil)
            
                        UIView.animate(withDuration: 0.5, delay: 0.5, options: UIView.AnimationOptions.curveEaseOut, animations:
                                        {
                                            self.Command.alpha = 1.0
                                        }, completion: nil)
                    }

                    if ((probeTmpInt > probeAlrmTmpInt) && probeAlrmIsArmd) {
                        if let audioPlayer = audioPlayer, audioPlayer.isPlaying
                            {  // }
                            }
                        else
                            {
                                guard let pathToSound = Bundle.main.path(forResource: "GrillProbeAlarm", ofType: "mp3") else { return }
                                let url = URL(fileURLWithPath: pathToSound)
                                do {
                                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                                    audioPlayer?.play()
                                
                                    stopProbeTempAlrmBttn.isHidden = false
                                }
                                catch {
                                    print ("something went wromg with probe alarm audio playback")
                                }
                                print ("you passed the alarm temp \(probeAlrmTmpInt)")
                            }
                        }
                    else
                    {
                        stopProbeTempAlrmBttn.isHidden = true
                    }                // charting app
                    
                    if(probefileEntryCounter == (probeCaptureDivider-1) && probefileEntryTotalCount < probeCaptureTotalCnt)
                    {
                        let dateTimeString = getDateTime()
                        if  ProbeTempString == "999" {// take care of temporary open thermistor readings
                           
                        if tempSecCaptureCnt2 > 1  {// simple filter to eliminate momentary open circuit conditions
                            let probeTempArrayString = probeTempArray[(Int(tempSecCaptureCnt2)-1)]
                            let probeTempArrayFloat = Float(probeTempArrayString) ?? 0.0
                            let probeTempFloat = Float(probeTmpInt)
                            
                            if (probeTempFloat > (probeTempArrayFloat + 150)) {
                                ProbeTempString = probeTempArray[(Int(tempSecCaptureCnt2)-1)]
                                }
                            if (probeTempFloat < (probeTempArrayFloat - 150)) {
                               ProbeTempString = probeTempArray[(Int(tempSecCaptureCnt2)-1)]
                                }
                            }
                        else {  ProbeTempString = "70"
                            }
                        }
                    
                        let probeTempTxt = ProbeTempString
                        probeTempArray.append(probeTempTxt)
                        // print ("ChartProbeTemp: \(probeTempArray)")
                        if ((tempSecCaptureCnt2 % Int32(probeChrtSamplePerMinInt/2)) == 0)//half the sample divider to move file write period to 1sec timebase
                        {
                            probeTempvsTimeString = (probeTempvsTimeString + "Date+Time," + dateTimeString + ", ProbeTemp," + " \(probeTempTxt)" + ",\(unit)\n")
                            
                            do {
                                    //Write to file
                                        try probeTempvsTimeString.write(to: setFileToDocumentsFolder(nameForFile: "ProbeTempvsTime", extForFile: "txt"), atomically: true, encoding: String.Encoding.utf8)
                                    
                                } catch let error as NSError { print("failed to write to URL")
                                    print(error.localizedDescription)
                                }
                                
                        }
                   
                    probefileEntryCounter = 0;
                    probefileEntryTotalCount += 1;   //
                    probechartSecondCnt.append(tempSecCaptureCnt)
                    probechartMinuteCnt.append(tempSecCaptureCnt/60)
                    }
                    else
                    {
                        if probefileEntryTotalCount < probeCaptureTotalCnt {
                        probefileEntryCounter += 1
                        }
                        else
                        {   //we've captured all the Chart Data points
                            probefileEntryCounter = 0
                            // GraphTempButton.isEnabled = true
                        }
                    }
                
                    tempSecCaptureCnt2 += 1

                    let DomeTemp = tempString.suffix(7);
                    let DomeTempString = String(DomeTemp)

                    let start = DomeTempString.index(DomeTempString.startIndex, offsetBy: 0);
                    let end = DomeTempString.index(DomeTempString.startIndex, offsetBy: 5 );
                    let range = start..<end;
                    var DomeTempString2 = DomeTempString[range];
                    if DomeTempString2.hasPrefix("0")
                        {
                            DomeTempString2.remove(at: DomeTempString2.startIndex)
                        }
                    
                    if (serverattachedString == "Gen20120") {
                        
                        if(scan_selectString == "resume_scanning")
                        {
                            if (passcnt == 0){
                                Command.textColor = UIColor.green
                                Command.text = String("\(DomeTempString2)\(unit)")
                                passcnt = 1
                                }
                            else {
                                Command.textColor = UIColor.white
                                Command.text = String("\(ProbeTemp)\(unit)")
                                passcnt = 0
                                }
                        }
                        if(scan_selectString == "scan_dome_only") {
                            Command.textColor = UIColor.green
                            Command.text = String("\(DomeTempString2)\(unit)")
                        }
                        if(scan_selectString == "scan_probe_only") {
                            Command.textColor = UIColor.white
                            Command.text = String("\(ProbeTemp)\(unit)")
                         }
                    }
                    if (serverattachedString == "Gen3.0")  {
                        domeChartButton.isHidden = false
                        settingsButton.isHidden = false
                        var unit2 = ""
                        var ProbeTempFloat = 0.0
                        
                        if (degFforProbePacket.contains("F")) {
                        unit2 = "°F"
                        print("Degree F")
                        }
                        if (degFforProbePacket.contains("C")) {
                        unit2 = "°C"
                        print("Degree C")
                            ProbeTempFloat = Double(ProbeTemp)!
                            ProbeTempFloat -= 32.0
                            ProbeTempFloat *= 0.55555
                            ProbeTempString = String(format: "%.0f", ProbeTempFloat)
                        }
                        if ProbeTempString.hasPrefix("0") {
                            ProbeTempString.remove(at: ProbeTempString.startIndex)
                        }
                        switch scan_selectString {
                        case "scan_probe_only":
                            Command.textColor = UIColor.white
                            Command.text = (ProbeTempString  + unit2)
                        case "resume_scanning":
                            Command.textColor = UIColor.white
                            Command.text = (ProbeTempString + unit2)
                        default:
                            scan_tempString = "resume_scanning"
                        }
                    }
                    if (serverattachedString == "Gen2.5")   {
                        domeChartButton.isHidden = false
                        settingsButton.isHidden = false
                        var unit2 = ""
                        var ProbeTempFloat = 0.0
                        
                        if (degFforProbePacket.contains("F")) {
                        unit2 = "°F"
                        print("Degree F")
                        }
                        if (degFforProbePacket.contains("C")) {
                        unit2 = "°C"
                        print("Degree C")
                            ProbeTempFloat = Double(ProbeTemp)!
                            ProbeTempFloat -= 32.0
                            ProbeTempFloat *= 0.55555
                            ProbeTempString = String(format: "%.0f", ProbeTempFloat)
                        }
                        if ProbeTempString.hasPrefix("0") {
                            ProbeTempString.remove(at: ProbeTempString.startIndex)
                        }
                        switch scan_selectString {
                        case "scan_probe_only":
                            Command.textColor = UIColor.white
                            Command.text = (ProbeTempString  + unit2)
                        case "resume_scanning":
                            Command.textColor = UIColor.white
                            Command.text = (ProbeTempString + unit2)
                        default:
                            scan_tempString = "resume_scanning"
                        }
                    }
                    
                    
                }
                if (tempString.contains("V")) {// "V" is batt volt when "gear" setting selected by user
            
                    batteryButton.isHidden = false
                    let distance = tempString.firstIndex(of: "V")!;
                    let Vindex = tempString.distance(from: tempString.startIndex, to: distance)
            
                    let batteryString = String(tempString)
                    print("tempString: \(tempString)")
                    print("Vindex: \(Vindex)")
                    let start = batteryString.index(batteryString.startIndex, offsetBy: (Vindex-4));
                    let end = batteryString.index(batteryString.startIndex, offsetBy: (Vindex-1));
                    let range = start..<end;
                    // let battery = tempString.suffix(10);
                    let batteryString2 = String(batteryString[range]);
                    
                    print("index of Battery: \(Vindex)")
                
                    battVoltage = Double(batteryString2)!
                    
                    print("Battery voltage String: \(batteryString2)")
                    
                    batteryString3 = "Battery Voltage = \(batteryString2)V"
                
                    if (battVoltage >= 3.9)
                    {
                        batteryButton.setImage(UIImage(named: "battery100.png"), for: UIControl.State.normal)
                    }
                    else if (battVoltage >= 3.7)
                    {
                        batteryButton.setImage(UIImage(named: "battery080.png"), for: UIControl.State.normal)
                    }
                    else if (battVoltage >= 3.5)
                    {
                        batteryButton.setImage(UIImage(named: "battery060.png"), for: UIControl.State.normal)
                    }
                    else if (battVoltage >= 3.4)
                    {
                        batteryButton.setImage(UIImage(named: "battery040.png"), for: UIControl.State.normal)
                    }
                    else if (battVoltage >= 3.3)
                    {
                        batteryButton.setImage(UIImage(named: "battery020.png"), for: UIControl.State.normal)
                    }
                    else
                    {
                        batteryButton.setImage(UIImage(named: "battery000.png"), for: UIControl.State.normal)
                    }
                    if (battVoltage <= 3.2) // in order to have the temperature blink to inform the user that the battery is low
                    {
                        UIView.animate(withDuration: 0.5, delay: 0.5, options: UIView.AnimationOptions.curveEaseOut, animations:
                                        {
                                            self.Command.alpha = 0.0
                                        }, completion: nil)

                        UIView.animate(withDuration: 0.5, delay: 0.5, options: UIView.AnimationOptions.curveEaseOut, animations:
                                        {
                                            self.Command.alpha = 1.0
                                        }, completion: nil)
                    }
        
                }
                if (tempString.contains("D")) {
                    if(serverattachedString == "Gen20120")
                    {
                        
                        var unit2 = "°F"
                        var DomeTempFloat = 0.0
                        var domeTmpInt: Int = 0
                        var DomeTempString2 = ""
                        domeChartButton.isHidden = false
     
                        let DomeTemp = tempString.suffix(7);
                        DomeTempString = String(DomeTemp)
         
                        let start = DomeTempString.index(DomeTempString.startIndex, offsetBy: 0);
                        let end = DomeTempString.index(DomeTempString.startIndex, offsetBy: 5 );
                        let range = start..<end;
                        DomeTempString2 = String(DomeTempString[range]);
                        if DomeTempString2.hasPrefix("0")
                            {
                                DomeTempString2.remove(at: DomeTempString2.startIndex)
                            }

                        print("String from server(-probe: \(tempString)")
                        print("GrillSentryDomeTemp: \(DomeTempString)")
                        print("the dome key counters cnt1:  \(tempSecCaptureCnt1)")

                        domeAlrmValueDsply.textAlignment = NSTextAlignment.right
                        domeAlrmValueDsply.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 16  )
                        domeAlrmValueDsply.minimumScaleFactor = 0.0001
            
                        domeAlrmValueDsply.backgroundColor = UIColor.clear
                        domeAlrmValueDsply.textColor = UIColor.green
                        if domeAlrmIsArmd {
                            let degFforProbePacket = "°F"
                            domeAlrmValueDsply.isHidden = false
                            domeAlrmValueDsply.text = String("DomeAlrm = \(domeAlrmTmpInt + 1)") + degFforProbePacket
                        }
                        else
                        {
                            domeAlrmValueDsply.isHidden = true
                            domeAlrmValueDsply.text = String("DomeAlrm = \(domeAlrmTmpInt + 1)")
                        }
                  
                        DomeTempFloat = Double(Float(DomeTempString2) ?? 0)
                        domeTmpInt = Int(DomeTempFloat)
                      
                        // Determimne if the Dome Temp Alarm has been exceeded
                        // initiate the audio alarm
                        if ((domeTmpInt > domeAlrmTmpInt) && domeAlrmIsArmd) {
                        
                            if let audioPlayer = audioPlayer, audioPlayer.isPlaying
                            {
                                print ("we think the audio player is playing")
                                // but alarm temp level has been reached
                            }
                            else
                                {
                                    guard let pathToSound = Bundle.main.path(forResource: "GrillDomeAlarm", ofType: "mp3") else { return }
                                    let url = URL(fileURLWithPath: pathToSound)
                                do {
                                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                                    audioPlayer?.play()
                                    stopDomeTempAlrmBttn.isHidden = false
                               
                                    }
                                    catch {
                                    print ("something went wromg with auduio player")
                                }
                                print ("you passed the alarm temp \(domeAlrmTmpInt)")
                            }
                        }
                        else
                        {
                            stopDomeTempAlrmBttn.isHidden = true
                        }
                    //only write the Dome Temp to file every 10th reading (or each 10 second interval)
                     //   var DomeTempString2 = DomeTempString    // save away for Charting only before degC conversiuon

                        if (tempString.contains("F")) {
                        unit2 = "°F"
                        degFforProbePacket = "F"
                        // print("Degree F")
                        }
                          
                        if (tempString.contains("C")) {
                        unit2 = "°C"
                        degFforProbePacket = "C"
                        //  print("Degree C")
                        DomeTempFloat = Double(DomeTempString)!
                        DomeTempFloat -= 32.0
                        DomeTempFloat *= 0.55555
                        DomeTempString = String(format: "%.1f", DomeTempFloat)
                        }
                    //    if(probefileEntryCounter == (probeCaptureDivider-1) && probefileEntryTotalCount < probeCaptureTotalCnt)
                        
                        if(domefileEntryCounter == (domeCaptureDivider-1) && domefileEntryTotalCount < domeCaptureTotalCnt)
                        {
                            let dateTimeString = getDateTime()
                             
                            var DomeTempFloat2 = Float(DomeTempString2)!
                            DomeTempFloat2 = round(DomeTempFloat2 * 10) / 10.0
                            let DomeTempString3 = String(format: "%.1f", DomeTempFloat2)

                            if tempSecCaptureCnt1 > 1
                            {
                                let domeTempArrayString = domeTempArray[(Int(tempSecCaptureCnt1)-1)]
                                let domeTempArrayFloat = Float(domeTempArrayString) ?? 0.0

                                if DomeTempFloat2 > (domeTempArrayFloat + 150)
                                {
                                 DomeTempString2 = domeTempArray[(Int(tempSecCaptureCnt1)-1)]
                                }
                                
                                if (DomeTempFloat2 < domeTempArrayFloat - 150)
                                {
                                 DomeTempString2 = domeTempArray[(Int(tempSecCaptureCnt1)-1)]
                                }
                            }
                            let DomeTempTxt = DomeTempString3   // save for charts
                            domeTempArray.append(DomeTempTxt)  // dome temp data array
                           
                            if ((tempSecCaptureCnt1 % Int32(domeChrtSamplePerMinInt)) == 0)
                            {
                                DomeTempvsTimeString = (DomeTempvsTimeString + "Date+Time," + dateTimeString + ", DomeTemp," + " \(DomeTempTxt)" + ",\(unit2)\n")
                               //  Write the DomeTemp and the capture time to a text file
                              
                                do {
                                //Write to file
                                try DomeTempvsTimeString.write(to: setFileToDocumentsFolder(nameForFile: "DomeTempvsTime", extForFile: "txt"), atomically: true, encoding: String.Encoding.utf8)
                                    } catch let error as NSError { print("failed to write to URL")
                                        print(error.localizedDescription)
                                    }
                                 /*
                                    var readString = ""
                                    do { readString = try String(contentsOf: domeTempvsTimeFileURL)}
                                    catch let error as NSError {
                                        print("failed to read file")
                                        print(error.localizedDescription)
                                    }
                                    print(readString)
                                */
                            }
                               //fileEntryCounter is chart recorder second divider
                                //fileEntryTotalCount is the total # of Chart entries
                                //ChartSecondCnt is the total #of seconds elapsed
                                domefileEntryCounter = 0;
                                domefileEntryTotalCount += 1;   //
                                domechartSecondCnt.append(tempSecCaptureCnt)
                                domechartMinuteCnt.append(tempSecCaptureCnt/60)
                              //  domechartMinuteCnt = round(domechartMinuteCnt * 10) / 10
                            }
                            else
                            {
                                if domefileEntryTotalCount < domeCaptureTotalCnt
                                {
                                domefileEntryCounter += 1
                                }
                                else
                                {   //we've captured all the Chart Data points
                                    domefileEntryCounter = 0
                                }
                            }
                            tempSecCaptureCnt1 += 1 // sample rate = 0.5/sec so multiply by 2 to get on use for Dome File Entry
                        
                            switch scan_selectString {
                            
                            case "resume_scanning":
                                Command.textColor = UIColor.green
                                Command.text = String("\(DomeTempString2)\(unit2)")
                            case "scan_dome_only":
                                Command.textColor = UIColor.green
                                Command.text = String("\(DomeTempString2)\(unit2)")
                            default:
                                scan_tempString = "resume_scanning"
                            }
                    }
                }
            }
            else
            {
                print("*****Other data Received from EggZact*****: \(dataBytes)" )
            }
         }
   }
        // MARK: - App lifecycle methods
    override func viewDidLoad()
    {
       for family: String in UIFont.familyNames
                {
                    print(family)
                    for names: String in UIFont.fontNames(forFamilyName: family)
                    {
                        print("== \(names)")
                    }
                }
       Command.isHidden = false
     
    
        blueLED.isHidden = true
        
        super.viewDidLoad()
      
     //   settingsButton.isHidden = false
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        /*
        let tap = UITapGestureRecognizer(target: self, action: #selector(resetStopwatch))
        tap.numberOfTapsRequired = 2
        display.addGestureRecognizer(tap)
        */
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(Connect(_:)))
        tap2.numberOfTapsRequired = 1
        Command.addGestureRecognizer(tap2)
        
        let screenSize = UIScreen.main.bounds
      //  let screenHeight = screenSize.height
        print("*****Screen height *****: \(screenSize.height)" )
      /*
        switch screenHeight
        {
        case 568: // iPhone 5/SE
            stopwatchOffset.constant = 80
            displayOffset.constant   = 100
       //    blueBlinkView.isHidden   = true
            break;
            
        case 667: // iPhone 6/7/8
            stopwatchOffset.constant = 98
            displayOffset.constant   = 122
            break;
            
        case 736: // iPhone 6/7/8 Plus
            stopwatchOffset.constant = 108
            displayOffset.constant   = 144
            break;
            
        case 812: // iPhone X
            stopwatchOffset.constant = 147
            displayOffset.constant   = 121
     //      blueBlinkView.isHidden   = true
            break;
            
        default:
            break;
        }
      */
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Settings and Stopwatch
    
    
    @objc func flashForConnect()
    {
        
        Command.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 60 )
      
      //  Command.textAlignment = NSTextAlignment.center
        Command.backgroundColor = UIColor.clear
        Command.textColor = UIColor.green

        if (connectCounter % 2 == 0)
        {
            Command.text = "Found GrillSentry"
        }
        else
        {
            Command.text = "Tap to Connect"
        }
        connectCounter+=1
    }
 
    @objc func flashBlueLED()
    {
        if (!blueLEDCntr)
        {
            
            blueLED.isHidden = false
        }
        else
        {
            
            blueLED.isHidden = true
        }
        
        blueLEDCntr = !blueLEDCntr
    }
    
    @IBAction func onTapCustomAlertButton(_ sender: Any) {
        if self.EggZact != nil
        {
            sendData("version")
            sendData("battvolt")
            sendData("RSSIGet")
            sendData("phystatus")
            sendData("frzdome")
         //   setTempAlrmBttn.isHidden = true
            scan_selectString = "scan_dome_only"
        }

       let customAlert = self.storyboard?.instantiateViewController(withIdentifier: "CustomAlertID") as! CustomAlertView
  
        
        customAlert.providesPresentationContextTransitionStyle = true
        customAlert.definesPresentationContext = true
        customAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        customAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        customAlert.delegate = self //this was commented out but '.delegate' is critical to operation of the delegate & protocol function
        self.present(customAlert, animated: true, completion: nil)
   
        customAlert.batteryLabel.text = batteryString3
        customAlert.versionLabel.text = versionString
        customAlert.PHYStatus.text = PHYStatusString1
        customAlert.unitSelector.selectedSegmentIndex = isCelcius ? 0 : 1
        customAlert.CVerLabel.text = clientVersionString
        customAlert.OffSetLabel.isHidden = true
        customAlert.GainLabel.isHidden = true
        customAlert.GainNegativeButton.isHidden = true
        customAlert.GainPositiveButton.isHidden = true
        customAlert.OffSetPositiveButton.isHidden = true
        customAlert.OffsetNegativeButton.isHidden = true
        
         
    }

    @IBAction func domeGraphTempStart(_ sender: Any) {
   
        let graphTemp = self.storyboard?.instantiateViewController(withIdentifier: "GraphScreenID") as! GraphTempView
        
        self.present(graphTemp, animated: true, completion: nil)
    
       }
   
    @IBAction func probeGraphTempStart(_ sender: Any) {
        
        let probeChart = self.storyboard?.instantiateViewController(withIdentifier: "probeGraphScreenID") as! probeGraphView
        
        self.present(probeChart, animated: true, completion: nil)
    }
    @IBAction func setTmpAlrms(_ sender: Any) {

        let setAlrmView = self.storyboard?.instantiateViewController(withIdentifier: "setAlrmViewID") as! setAlarmTmps
    
    self.present(setAlrmView, animated: true, completion: nil)

}
    @IBAction func stopDomeTempAlrm(_ sender: Any) {
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying{
        audioPlayer.stop()
        
        }
      //  probeAlrmIsArmd = false
        domeAlrmIsArmd = false
        stopDomeTempAlrmBttn.isHidden = true
        domeAlrmTmpInt = 749 //reset the alarm setting // force the user to re-enter an alarm poimt
     }
 
    @IBAction func stopProbeTempAlrm(_ sender: Any) {
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying{
        audioPlayer.stop()
        
        }
        probeAlrmIsArmd = false
      //  domeAlrmIsArmd = false
        stopProbeTempAlrmBttn.isHidden = true
        probeAlrmTmpInt = 499 // reset the alarm setting // force the user to re-enter an alarm poimt
        
    }
   
    func saveProbeChrtToFilePicker() {
        self.dismiss(animated: true, completion: nil)

        let saveProbeChrtView = self.storyboard?.instantiateViewController(withIdentifier: "saveProbeCharttoDocuments") as! saveProbeChartToFileView
    
        self.present(saveProbeChrtView, animated: true, completion: nil)
        
        let ProbeTempvsTimeFileURL = setFileToDocumentsFolder(nameForFile: "ProbeTempvsTime", extForFile: "txt")
        
        let exportMenu = UIDocumentPickerViewController(url: ProbeTempvsTimeFileURL, in: .exportToService)
        //   let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypePDF)], in: .import)
            exportMenu.delegate = self
            exportMenu.modalPresentationStyle = .formSheet
            self.present(exportMenu, animated: true, completion: nil)
    }
    
    func saveDomeChrtToFilePicker() {
        
        self.dismiss(animated: true, completion: nil)

        let saveDomeChrtView = self.storyboard?.instantiateViewController(withIdentifier: "saveDomeCharttoDocuments") as! saveDomeChartToFileView
   
        self.present(saveDomeChrtView, animated: true, completion: nil)
       
        let DomeTempvsTimeFileURL = setFileToDocumentsFolder(nameForFile: "DomeTempvsTime", extForFile: "txt")
      
        let exportMenu = UIDocumentPickerViewController(url: DomeTempvsTimeFileURL, in: .exportToService)
        //   let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypePDF)], in: .import)
            exportMenu.delegate = self
            exportMenu.modalPresentationStyle = .formSheet
            self.present(exportMenu, animated: true, completion: nil)
    }
    
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
         // just send back the first one, which ought to be the only one
        return paths[0]
    }
  
 
    func setFileToDocumentsFolder(nameForFile: String, extForFile: String) -> URL {

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileURL = documentsURL!.appendingPathComponent(nameForFile).appendingPathExtension(extForFile)
        return fileURL
        }
    func getDateTime() -> String {
    
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "your_loc_id")
        formatter.dateFormat = "yyyy-MM-dd'T'yyyy:MM:HH:mm:ss"
        //  formatter.setLocalizedDateFormatFromTemplate("HH:mm:ss")
        formatter.amSymbol = ""
        formatter.pmSymbol = ""
        formatter.timeStyle = .medium
        formatter.dateStyle = .short

        let dateTime = formatter.string(from: currentDateTime)
        
        return dateTime
    }
    
    /*
     
     Document Picker support
     
     */
    @available(iOS 14.0, *)
    func selectFiles() {
        let types = UTType.types(tag: "txt", tagClass: UTTagClass.filenameExtension, conformingTo: nil)
   
        let documentPickerController = UIDocumentPickerViewController(
            forOpeningContentTypes: types)
            documentPickerController.delegate = self
        self.present(documentPickerController, animated: true, completion: nil)
}
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let myURL = urls.first else {
            return
        }
        print("import result : \(myURL)")
    }
    
    public func documentMenu(_ documentMenu:UIDocumentPickerViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
        
    }
    
}
