
//
//  EggZact_v2_ViewController.swift
//  EggZact_v2
//
//  Created by Ken Sticher on 9/26/17.
//
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate
{
    // MARK: Properties
    
    @IBOutlet weak var Probe:            UILabel!
    @IBOutlet weak var Command:          UILabel!
    //@IBOutlet weak var Probe:            UILabel!
    @IBOutlet weak var display:          UIButton!
    @IBOutlet weak var settingsButton:   UIButton!
    @IBOutlet weak var batteryButton:    UIButton!
    @IBOutlet weak var blueBlinkView:    UIView!
    @IBOutlet weak var stopwatchOffset:  NSLayoutConstraint!
    @IBOutlet weak var settingsOffset:   NSLayoutConstraint!
    @IBOutlet weak var displayOffset:    NSLayoutConstraint!
    
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
    var battVoltageString    = ""
    var versionString        = ""
    var didTapDisconnect     = false
    
    var tempTimer:    Timer?
    var batteryTimer: Timer?
    
    var connectCounter:UInt8 = 0
    var connectTimer: Timer?
    var alreadyConnected: Bool = false
    
    var tempCount            = 0;
    var firstReadingObtained = false
    var isDome               = false

    
    /***********************************************************************************************************************************/
    
    // MARK: - BLE commands
    func sendData (_ message: String)
    {
        if let data = (message + "\r").data(using: String.Encoding.utf8)
        {
            if let EggZact = self.EggZact
            {
                EggZact.writeValue(data as Data, for: self.sendbuffer!, type: .withResponse)
                //print("\(message) command sent to EggZact")
            }
        }
    }
    
    @objc func pingforTemp()
    { sendData("tempOn") }
    
    @objc func pingforVersion()
    { sendData("version") }
    
    @objc func pingForBattery()
    { sendData("battvolt") }
    
    func tempON()
    { sendData("tempOn") }
    
    func tempOFF()
    { sendData("tempOff") }
    
    @IBAction func Connect(_ sender: Any)
    {
        if alreadyConnected {return}
        if let EggZact = self.EggZact
        {
            centralManager.connect(EggZact, options: nil)
            settingsButton.isHidden   = false
        }
    }
    
    // MARK: - CBCentralManagerDelegate methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) // Invoked when the central manager’s state is updated.
    {
        var showAlert = true
        var message = ""
        
        switch central.state {
        case .poweredOff:   message = "Bluetooth on this device is currently powered off."
        case .unsupported:  message = "This device does not support Bluetooth Low Energy."
        case .unauthorized: message = "This app is not authorized to use Bluetooth Low Energy."
        case .resetting:    message = "The BLE Manager is resetting; a state update is pending."
        case .unknown:      message = "The state of the BLE Manager is unknown."
        case .poweredOn:
            showAlert = false
            message = "Bluetooth LE is turned on and ready for communication."
            print(message)
            centralManager.scanForPeripherals(withServices: nil, options: nil) // Option 1: Scan for all devices
            // Option 2: Scan for devices that have the service you're interested in...
            //let sensorTagAdvertisingUUID = CBUUID(string: Device.SensorTagAdvertisingUUID)
            //print("Scanning for EggZact adverstising with UUID: \(sensorTagAdvertisingUUID)")
            //centralManager.scanForPeripheralsWithServices([sensorTagAdvertisingUUID], options: nil)
            //centralManager.scanForPeripherals(withServices: [sensorTagAdvertisingUUID], options: nil)
        }
        
        if showAlert
        {
            let alertController = UIAlertController(title: "Central Manager State", message: message, preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            self.show(alertController, sender: self)
        }
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
            
            if peripheralName == "GrlSentry POGI"
            {
                connectCounter = 0
                connectTimer = Timer.scheduledTimer(timeInterval:  1.0, target: self, selector: #selector(flashForConnect), userInfo: nil, repeats: true)
                print("EggZact Thermometer found! Press Connect to Add!!")
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
        print("**** SUCCESSFULLY CONNECTED TO EggZact Thermometer !")
        
        // Now that we've successfully connected to the SensorTag, let's discover the services.
        // - NOTE:  we pass nil here to request ALL services be discovered.
        //          If there was a subset of services we were interested in, we could pass the UUIDs here.
        //          Doing so saves battery life and saves time.
        
        alreadyConnected = true
        Command.text = "Connected"
        peripheral.discoverServices(nil)
        connectTimer?.invalidate()
        tempTimer    = Timer.scheduledTimer(timeInterval:  2.0, target: self, selector: #selector(pingforTemp),    userInfo: nil, repeats: true)
        _            = Timer.scheduledTimer(timeInterval:  2.0, target: self, selector: #selector(pingforVersion), userInfo: nil, repeats: false)  // just need version once
        _            = Timer.scheduledTimer(timeInterval:  2.0, target: self, selector: #selector(pingForBattery), userInfo: nil, repeats: false) // to get an initial reading...
        batteryTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(pingForBattery), userInfo: nil, repeats: true) // ...and once a minute afterwards
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
        print("**** DISCONNECTED FROM EggZact Thermometer!!!")
        if error != nil {
            print("****** DISCONNECTION DETAILS: \(error!.localizedDescription)")
        }
        EggZact = nil
        Command.text = "Disconnected"
        settingsButton.isHidden = true
        batteryButton.isHidden  = true
        tempTimer?.invalidate()
        batteryTimer?.invalidate()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
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
                    let bytes : [UInt8] = [ 0x54, 0x45, 0x4D, 0x50, 0x4F, 0x4E, 0x0d ]  // TempOn
                    let data = NSData(bytes: bytes, length: bytes.count)
                    EggZact?.writeValue(data as Data, for: characteristic, type: .withResponse)
                }
            }
        }
    }
    
    /* Invoked when you retrieve a specified characteristic’s value, or when the peripheral device notifies your app that the characteristic’s value has changed.
     This method is invoked when your app calls the readValueForCharacteristic: method,
     or when the peripheral notifies your app that the value of the characteristic for which notifications and indications are enabled has changed. */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
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
                //print("Data Received from EggZact: \(dataBytes)" ) // this just gives the number of bytes, e.g. "12 bytes"
                
                var tempString = ""
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
                    if tempString.hasPrefix("0")
                    {
                        tempString.remove(at: tempString.startIndex)
                    }
                }
                
                if (tempString.contains("H"))     // is this the S/W version string?
                {
                    versionString     = ("Version: \(tempString)")
                }
                
                if (tempString.contains("V"))     // is this the battery voltage value string?
                {
                    batteryButton.isHidden = false
                    battVoltageString = ("Battery: \(tempString)")
                    tempString = tempString.replacingOccurrences(of: "V", with: "")
                    battVoltage = NSString(string: tempString).doubleValue
                    print("Battery voltage float: \(battVoltage)")
                    
                    if (battVoltage >= 3.9)
                    {
                        batteryButton.setImage(UIImage(named: "battery100.png"), for: UIControlState.normal)
                    }
                    else if (battVoltage >= 3.7)
                    {
                        batteryButton.setImage(UIImage(named: "battery080.png"), for: UIControlState.normal)
                    }
                    else if (battVoltage >= 3.5)
                    {
                        batteryButton.setImage(UIImage(named: "battery060.png"), for: UIControlState.normal)
                    }
                    else if (battVoltage >= 3.4)
                    {
                        batteryButton.setImage(UIImage(named: "battery040.png"), for: UIControlState.normal)
                    }
                    else if (battVoltage >= 3.3)
                    {
                        batteryButton.setImage(UIImage(named: "battery020.png"), for: UIControlState.normal)
                    }
                    else
                    {
                        batteryButton.setImage(UIImage(named: "battery000.png"), for: UIControlState.normal)
                    }
                }
                
                if (tempString.contains("T"))     // is this the thermocouple temp value string?
                {
                    tempString = tempString.replacingOccurrences(of: "T", with: "")
                    tempString = tempString.replacingOccurrences(of: " ", with: "")
                    let unit = isCelcius ? "°C" : "°F"
                    
                    var arr = tempString.components(separatedBy: ".")
                    if ((arr[1] != "0") && (firstReadingObtained == false))
                    {
                        isDome = true
                        firstReadingObtained = true
                    }

                    if (firstReadingObtained == true)
                    {
                        if (isDome)
                        {
                            print("EggZact temperature: \(tempString)\n")
                            Command.text = (tempString + unit)
                            isDome.toggle()
                        }
                        else
                        {
                            print("Probe temperature: \(tempString)\n")
                            Probe.text = (tempString + unit + " Probe")
                            isDome.toggle()
                        }
                    }
                    
                    /*
                    tempCount = tempCount+1
                    if (tempCount % 2 == 0)
                    {
                        print("EggZact temperature: \(tempString)\n")
                        Command.text = (tempString + unit)
                    }
                    else
                    {
                        print("Probe temperature: \(tempString)\n")
                        Probe.text = (tempString + unit + " Probe")
                    }
                    */
                    
                    self.blueBlinkView.alpha = 1.0
                    UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                        self.blueBlinkView.alpha = 0.0
                    }, completion: nil)
                    
                    
                    //Command.text = (tempString + unit)
                    
                    if (battVoltage <= 3.2) // in order to have the temperature blink to inform the user that the battery is low
                    {
                        
                        UIView.animate(withDuration: 0.5, delay: 0.5, options: UIViewAnimationOptions.curveEaseOut, animations:
                            {
                                self.Command.alpha = 0.0
                        }, completion: nil)
                        
                        UIView.animate(withDuration: 0.5, delay: 0.5, options: UIViewAnimationOptions.curveEaseOut, animations:
                            {
                                self.Command.alpha = 1.0
                        }, completion: nil)
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
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(resetStopwatch))
        tap.numberOfTapsRequired = 2
        display.addGestureRecognizer(tap)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(Connect(_:)))
        tap2.numberOfTapsRequired = 1
        Command.addGestureRecognizer(tap2)
        
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height
        print("*****Screen height *****: \(screenSize.height)" )
        
        switch screenHeight
        {
        case 568: // iPhone 5/SE
            stopwatchOffset.constant = 80
            displayOffset.constant   = 100
            blueBlinkView.isHidden   = true
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
            blueBlinkView.isHidden   = true
            break;
            
        default:
            break;
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Settings and Stopwatch
    @objc func resetStopwatch()
    {
        stopWatch.invalidate()
        startTime = 0
        time      = 0
        elapsed   = 0
        stopwatchRunning    = false
        display.setTitle("00:00:00", for: .normal)
    }
    
    @IBAction func toggleStartStop(_ sender: UIButton!)
    {
        if (stopwatchRunning) {
            stop()
        } else {
            start()
        }
    }
    
    func start()
    {
        startTime = Date().timeIntervalSinceReferenceDate - elapsed
        stopWatch = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateStopwatch), userInfo: nil, repeats: true)
        stopwatchRunning = true
    }
    
    func stop()
    {
        elapsed = Date().timeIntervalSinceReferenceDate - startTime
        stopWatch.invalidate()
        stopwatchRunning = false
    }
    
    @objc func updateStopwatch()
    {
        time = Date().timeIntervalSinceReferenceDate - startTime // Calculate total time since timer started
        
        let hours   = UInt8(time / 3600.0)
        
        let minutes = UInt8(time / 60.0)
        time -= (TimeInterval(minutes) * 60)
        
        let seconds = UInt8(time)
        time -= TimeInterval(seconds)
        
        let strHours   = String(format: "%02d", hours)
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        
        if (seconds % 2 == 0) // in order to have the colon blink to inform the user that the timer has been activiated
        {
            display.setTitle("\(strHours):\(strMinutes):\(strSeconds)", for: .normal)
        }
        else
        {
            display.setTitle("\(strHours):\(strMinutes).\(strSeconds)", for: .normal)
        }
    }
    
    @objc func flashForConnect()
    {
        if (connectCounter % 2 == 0)
        {
            Command.text = "Found EggZact"
        }
        else
        {
            Command.text = "Tap to Connect"
        }
        connectCounter+=1
    }
    
    @IBAction func onTapCustomAlertButton(_ sender: Any) {
        if self.EggZact != nil
        {
            sendData("version")
            sendData("battvolt")
        }
        
        let customAlert = self.storyboard?.instantiateViewController(withIdentifier: "CustomAlertID") as! CustomAlertView
        customAlert.providesPresentationContextTransitionStyle = true
        customAlert.definesPresentationContext = true
        customAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        customAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        customAlert.delegate = self
        self.present(customAlert, animated: true, completion: nil)
        customAlert.batteryLabel.text = battVoltageString
        customAlert.versionLabel.text = versionString
        customAlert.unitSelector.selectedSegmentIndex = isCelcius ? 0 : 1
    }
}

// MARK: - Methods called from the Settings screen
extension ViewController: CustomAlertViewDelegate {
    
    func disconnectButtonTapped() {
        print("disconnectButtonTapped")
        didTapDisconnect = true
        if let EggZact = self.EggZact
        {
            let bytes : [UInt8] =      [ 0x54, 0x45, 0x4D, 0x50, 0x4F, 0x46, 0x46, 0x0d ]  // TempOFF
            //byte[] bMessage = new byte[]{0x54, 0x45, 0x4d, 0x50, 0x4f, 0x46, 0x46, 0x0d}; // Send EggZact's TempOFF Command
            let data = NSData(bytes: bytes, length: bytes.count)
            EggZact.writeValue(data as Data, for: self.sendbuffer!, type: .withResponse)
            
            if let tc = self.sendbuffer
            {
                EggZact.setNotifyValue(false, for: tc)
            }
            
            centralManager.cancelPeripheralConnection(EggZact) // From your app’s perspective the peripheral is considered disconnected. centralManager:didDisconnectPeripheral is called
            //centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
        EggZact = nil
        //sendbuffer = nil
        Command.text = "Disconnected"
        alreadyConnected = false
        settingsButton.isHidden = true
        batteryButton.isHidden  = true
    }
    
    func closeButtonTapped() {
        print("closeButtonTapped")
    }
    
    func changeUnits(selectedOption: String)
    {
        isCelcius = !isCelcius
        switch selectedOption as String
        {
        case "°C": sendData("degC")
        case "°F": sendData("degF")
        default: break;
        }
        print(isCelcius)
    }
    
    func CalON()    { sendData("calErase") }
    func CalOFF()   { sendData("calWrite") }
    func VrefUP()   { sendData("vRefUp")   }
    func VrefDOWN() { sendData("vRefDwn")  }
}


