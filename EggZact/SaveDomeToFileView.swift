//
//  SaveToDomeFileView.swift
//  GrillSentry
//
//  Created by Ken Sticher on 8/16/21.
//  Copyright © 2021 Ken Sticher. All rights reserved.
//
import Foundation
import SwiftUI
import UIKit
import TinyConstraints
import Charts
import AVFoundation
import MobileCoreServices

var domeChrtSamplePerMinInt: Int8 = 4
var domeChrtSamplePerMinInt2: Int8 = 4


class saveDomeChartToFileView: UIViewController, UIDocumentPickerDelegate, UINavigationControllerDelegate
{
    

    @IBOutlet weak var saveDomeToFileBttn: UIButton!
    
    @IBAction func saveDomeToFile(_ sender: Any) {
        exportDomeChrtMenu()
        
    }
    
    @IBOutlet weak var domeChrtSmplLbl: UITextField!
    
    
    @IBOutlet weak var domeChartSampleRateLbl: UILabel!
    
   
    @IBOutlet weak var domeChrtSmplStppr: UIStepper!
    
    @IBAction func domeChrtSmplStppr(_ sender: UIStepper) {
        
        domeChrtSamplePerMinInt2 = Int8(sender.value)
        domeChrtSmplLbl.text = String(domeChrtSamplePerMinInt2)
        print (sender.value)
        
    }
   
   
    func exportDomeChrtMenu() {
       
        
        let DomeTempvsTimeFileURL = getDocumentsDirectory().appendingPathComponent("DomeTempvsTime.txt")
        
        //delegate?.getDocumentsDirectory().appendingPathComponent("DomeTempvsTime.txt")
      
        let exportMenu = UIDocumentPickerViewController(url: DomeTempvsTimeFileURL, in: .exportToService)
        //   let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypePDF)], in: .import)
            exportMenu.delegate = self
            exportMenu.modalPresentationStyle = .formSheet
            self.present(exportMenu, animated: true, completion: nil)
        
    }
   
     
    @IBOutlet weak var exitSaveToFileBttn: UIButton!
 
    @IBAction func exitSaveToFile(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
   
    override func viewDidLoad(){
    super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
     //   exportDomeChrtMenu()
        if probeAttached {
            domeChrtSamplePerMinInt = (domeChrtSamplePerMinInt2 / 2)
         }
        else
        {   domeChrtSamplePerMinInt = domeChrtSamplePerMinInt2
        }
         
        setupDomeLabels()
        
     }
    
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
  
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
         // just send back the first one, which ought to be the only one
        return paths[0]
    }
   
    func setupDomeLabels()
    {
    domeChrtSmplLbl.textAlignment = NSTextAlignment.center
    domeChrtSmplLbl.text = String(domeChrtSamplePerMinInt2)
    domeChrtSmplLbl.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 36  )
    domeChrtSmplLbl.backgroundColor = UIColor.black
    domeChrtSmplLbl.textColor = UIColor.green
    self.view.addSubview(domeChrtSmplLbl)

        domeChartSampleRateLbl.textAlignment = NSTextAlignment.center
        domeChartSampleRateLbl.text = "Enter Dome Chart Log File Sample Rate (sample per minute)"
        domeChartSampleRateLbl.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 12  )
        domeChartSampleRateLbl.backgroundColor = UIColor.black
        domeChartSampleRateLbl.textColor = UIColor.green
    self.view.addSubview(domeChartSampleRateLbl)
  //  domeChrtSampleRate.stepValue = 2}
    }

}
