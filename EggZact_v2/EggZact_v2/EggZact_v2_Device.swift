//
//  BLEConstants.swift
//  iOSRemoteConfBLEDemo
//
//  Created originally by Evan Stone on 4/9/16.
//  Modified custom for EggZact by Ken Sticher 9/15/58
//

import Foundation


//------------------------------------------------------------------------
// Information about Texas Instruments SensorTag UUIDs can be found at:
// http://processors.wiki.ti.com/index.php/SensorTag_User_Guide#Sensors
//------------------------------------------------------------------------
// From the TOSHIBA documentation:
//  The UUID for Toshiba's SPPoverBLE Exchange Data Buffer is a 16byte long string
//  "B38312C0-AA89-11E3-9CEF-0002A5D5C51B"
//
//------------------------------------------------------------------------

struct Device {
    
  // ks this structure taken from Evan Stone and TI sensor application
  // many parts not applicable for EggZact
    
   // static let SensorTagAdvertisingUUID = "63C91A34-AF9F-5511-85EC-F417D5E2A04B"
    static let BGETagAdvertisingUUID = "63C91A34-AF9F-5511-85EC-F417D5E2A04B"
    // ks   static let TemperatureServiceUUID = "F000AA00-0451-4000-B000-000000000000"
    static let TemperatureServiceUUID = "E079C6A0-AA8B-11E3-A903-0002A5D5C51B"
    
 // Server side SPPoverBLE refers to this UUID as the Exchange Data Buffer
    static let TemperatureDataUUID = "B38312C0-AA89-11E3-9CEF-0002A5D5C51B"
    
 //   static let TemperatureConfig = "F000AA02-0451-4000-B000-000000000000"
    static let TemperatureConfig = "B38312C0-AA89-11E3-9CEF-0002A5D5C51B"
    
    static let HumidityServiceUUID = "F000AA20-0451-4000-B000-000000000000"
    static let HumidityDataUUID    = "F000AA21-0451-4000-B000-000000000000"
    static let HumidityConfig      = "F000AA22-0451-4000-B000-000000000000"

    static let SensorDataIndexTempInfrared = 0
    static let SensorDataIndexTempAmbient = 1
    static let SensorDataIndexHumidityTemp = 0
    static let SensorDataIndexHumidity = 1
}
