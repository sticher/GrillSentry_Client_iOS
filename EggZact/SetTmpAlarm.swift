//
//  SetTemperature Alarms
//  GrillSentry
//
//  Created by Ken Sticher on 8/10/21.
//  Copyright © 2021 Ken Sticher. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit
import Charts
import TinyConstraints
import AVFoundation

var probeAlrmTmpInt: Int = 249
var domeAlrmTmpInt: Int = 749

   
class setAlarmTmps: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
 
    var usrSelectFoodontheGrill = ""
    var usrSelectProbeAlrmTemp = ""
    var usrSelectProbeAlrmTXT = ""
    var probeAlrmString = ""

    @IBOutlet weak var grillTemps: UIPickerView!
    var grillProbeTempsData:[String] = [String]()
    
    @IBOutlet weak var foodTypes: UIPickerView!
    var foodTypesData:[String] = [String]()
    
    
    @IBOutlet weak var exitAlrmScrnBttn: UIButton!
    
    
       
    @IBAction func exitSetAlrmScrnBttn(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        
    }
    @IBOutlet weak var suggestedProbeAlrmTemp: UILabel!
    
    @IBOutlet weak var domeAlrmTempInputs: UITextField!
    @IBOutlet weak var probeAlarmTempInputs: UITextField!
    @IBOutlet weak var enterDomeAlrmTempBttn: UIButton!
    @IBOutlet weak var enterProbeAlrmTempBttn: UIButton!
   
    // Capture the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
           // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        let degFforProbePacket = "°F"
        
        if pickerView.tag == 1
        {
            usrSelectFoodontheGrill = foodTypesData[row]
            print("food selected was \(usrSelectFoodontheGrill) \n\n")
        }
      
        if pickerView.tag == 2
        {
            usrSelectProbeAlrmTemp = grillProbeTempsData[row]
            print("selected grill temp = \(usrSelectProbeAlrmTemp) \n\n")
        }
       
        usrSelectProbeAlrmTemp = grillEvent(food: usrSelectFoodontheGrill, cookType: usrSelectProbeAlrmTemp)
   
        suggestedProbeAlrmTemp.textAlignment = NSTextAlignment.center
        let suggestedProbeAlrmTXT = usrSelectProbeAlrmTemp
        suggestedProbeAlrmTemp.text = suggestedProbeAlrmTXT + degFforProbePacket
   
        probeAlarmTempInputs.textAlignment = NSTextAlignment.center
        usrSelectProbeAlrmTXT = usrSelectProbeAlrmTemp
        probeAlrmString = usrSelectProbeAlrmTXT
        probeAlarmTempInputs.text = usrSelectProbeAlrmTXT + degFforProbePacket
        
        return
       
    }
 
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
      //  return string == string.filter("0123456789".contains)
        let acceptedCharacters = "+1234567890"
        let acceptedCharacterSet = CharacterSet(charactersIn: acceptedCharacters)
        let typingCharacterSet = CharacterSet(charactersIn: string)
        return acceptedCharacterSet.isSuperset(of: typingCharacterSet)
        
    }
   
   // configureDomeTxtField()

    override func viewDidLoad(){
    super.viewDidLoad()
        
        self.foodTypes.delegate = self
        self.foodTypes.dataSource = self
        foodTypes.tag = 1
        foodTypesData = ["beef steak", "beef hamburger", "chicken", "pork loin", "salmon" ]

        self.grillTemps.delegate = self
        self.grillTemps.dataSource = self
      
        grillProbeTempsData = ["well done", "medium well done", "medium", "medium rare", "minimum safe temperature"]
        
        suggestedProbeAlrmTemp.textAlignment = NSTextAlignment.center
    //    suggestedProbeAlrmTemp.delegate = self
        suggestedProbeAlrmTemp.text = "Select your food & grill"
        suggestedProbeAlrmTemp.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 28      )
        suggestedProbeAlrmTemp.backgroundColor = UIColor.black
        suggestedProbeAlrmTemp.textColor = UIColor.white
        self.view.addSubview(suggestedProbeAlrmTemp)
        

        domeAlrmTempInputs.delegate = self
        probeAlarmTempInputs.delegate = self
        
        domeAlrmTempInputs.textAlignment = NSTextAlignment.center
        domeAlrmTempInputs.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 36  )
        domeAlrmTempInputs.backgroundColor = UIColor.black
        domeAlrmTempInputs.textColor = UIColor.green
        domeAlrmTempInputs.text = "Dome Alarm Temperature"
        self.view.addSubview(domeAlrmTempInputs)
        
        probeAlarmTempInputs.textAlignment = NSTextAlignment.center
         probeAlarmTempInputs.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 36    )
        probeAlarmTempInputs.backgroundColor = UIColor.black
        probeAlarmTempInputs.textColor = UIColor.white
        probeAlarmTempInputs.text = "Probe Alarm Temperature"
        self.view.addSubview(probeAlarmTempInputs)
         
    }
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
        
    }
 
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        probeAlrmString = probeAlarmTempInputs.text ?? "450"
        probeAlarmTempInputs.resignFirstResponder()
        domeAlrmTempInputs.resignFirstResponder()
    }
  
    @IBAction func enterDomeAlrmTapped(_ sender: Any) {
        if let domeAlrmString = domeAlrmTempInputs.text {
            domeAlrmTmpInt = Int(domeAlrmString) ?? 750
            domeAlrmTmpInt = domeAlrmTmpInt - 1
            domeAlrmIsArmd = true
        }
        
    }
    @IBAction func enterProbeAlrmTapped(_ sender: Any) {
        let degFforProbePacket = "°F"
        if probeAlarmTempInputs.text ==  usrSelectProbeAlrmTXT + degFforProbePacket
        {
            probeAlrmTmpInt = Int(usrSelectProbeAlrmTXT) ?? 250
            probeAlrmTmpInt = probeAlrmTmpInt - 1 // take care of > integer
            probeAlrmIsArmd = true
        }//    probeAlrmString = probeAlarmTempInputs.text ?? "450"
        else
        {
            probeAlrmString = probeAlarmTempInputs.text!
            probeAlrmTmpInt = Int(probeAlrmString) ?? 250
            probeAlrmTmpInt = probeAlrmTmpInt - 1 // take care of > integer
            probeAlrmIsArmd = true
          }
    }
  
    // number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1
        { return foodTypesData.count }
        else if pickerView.tag == 2
        { return grillProbeTempsData.count}
        return 1
    }
      
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerView.tag == 1
        {
    //    var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 24)
            pickerLabel?.textAlignment = .center
            pickerLabel?.backgroundColor = .darkGray
        }
        pickerLabel?.text = foodTypesData[row]
        pickerLabel?.textColor = UIColor.white

        return pickerLabel!
        }
        else if pickerView.tag == 2
        {
      //      var pickerLabel: UILabel? = (view as? UILabel)
            if pickerLabel == nil {
                pickerLabel = UILabel()
                pickerLabel?.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 24)
                pickerLabel?.textAlignment = .center
                pickerLabel?.backgroundColor = .darkGray
            }
            pickerLabel?.text = grillProbeTempsData[row]
            pickerLabel?.textColor = UIColor.white

            return pickerLabel!
        }
            
          return pickerLabel!
    }
    
    
    // The data to return for the row and component (column) that's being passed in
   /*
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1
            {
            return foodTypesData[row]
  
            }
        else if pickerView.tag == 2
            {
            return grillProbeTempsData[row]
            }
        return ""
    }
  */
}
extension setAlarmTmps: UITextFieldDelegate {
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
    
func grillEvent( food: String, cookType: String) -> String {
    
    if food == "beef steak"
    {
    switch cookType
        {
        case "well done":
        return "165"
        case "medium well done":
        return "160"
        case "medium":
        return "155"
        case "medium rare":
        return "150"
        case "minimum safe temperature":
        return "145"
     default:
        break;
        }
    }
    if food == "beef hamburger"
    {
    switch cookType
        {
        case "well done":
        return "165"
        case "medium well done":
        return "163"
        case "medium":
        return "162"
        case "medium rare":
        return "161"
        case "minimum safe temperature":
        return "160"
     default:
        break;
        }
    }
    if food == "chicken"
        {
        switch cookType
            {
            case "well done":
            return "165"
            case "medium well done":
            return "160"
            case "medium":
            return "155"
            case "medium rare":
            return "152"
            case "minimum safe temperature":
            return "150"
         default:
            break;
            }
    }
    if food == "pork loin"
        {
        switch cookType
            {
            case "well done":
            return "160"
            case "medium well done":
            return "158"
            case "medium":
            return "155"
            case "medium rare":
            return "150"
            case "minimum safe temperature":
            return "145"
         default:
            break;
            }
    }
    if food == "salmon"
        {
        switch cookType
            {
            case "well done":
            return "155"
            case "medium well done":
            return "145"
            case "medium":
            return "135"
            case "medium rare":
            return "125"
            case "minimum safe temperature":
            return "120"
         default:
            break;
            }
    }
    else { print(" found no cookType string")
        
    }
    return ""
}
    
