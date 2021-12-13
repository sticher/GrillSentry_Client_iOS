//
//  SaveProbeToFileView.swift
//  GrillSentry
//
//  Created by Ken Sticher on 8/17/21.
//  Copyright © 2021 Ken Sticher. All rights reserved.
//  Modifications Dec2022

import Foundation
import SwiftUI
import UIKit
import TinyConstraints
import Charts
import AVFoundation
import MobileCoreServices

var probeChrtSamplePerMinInt: Int8 = 4


class saveProbeChartToFileView: UIViewController, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    
    //  var delegate: SaveToFileViewDelegate?
  //  var delegate: setFileToDocumentsFolder(){}?
    
    @IBOutlet weak var probeChrtSmplLbl: UILabel!
    
    @IBOutlet weak var saveProbeChrtToFileBttn: UIButton!
     
    @IBOutlet weak var exitSaveProbeChrtToFileBttn: UIButton!
    
    @IBOutlet weak var probeChrtSmplPerMin: UIStepper!
    
    @IBOutlet weak var ProbeChrtLabel: UILabel!
    
    
    @IBAction func probeStepperPressed(_ sender: UIStepper) {
        
        probeChrtSamplePerMinInt = Int8(sender.value)
        probeChrtSmplLbl.text = String(probeChrtSamplePerMinInt)
        print (sender.value)
    }
   
    @IBAction func saveProbeChrtToFile(_ sender: Any) {
        exportProbeChrtMenu()
        
    }
   
    @IBAction func exitSaveProbeChrtFileBttn(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        
    }

    func exportProbeChrtMenu() {
        
         //   delegate? .setFileToDocumentsFolder(nameForFile: "DomeTempvsTime", extForFile: "txt")
        
        let ProbeTempvsTimeFileURL = getDocumentsDirectory().appendingPathComponent("ProbeTempvsTime.txt")
      
        let exportProbeMenu = UIDocumentPickerViewController(url: ProbeTempvsTimeFileURL, in: .exportToService)
        //   let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypePDF)], in: .import)
            exportProbeMenu.delegate = self
            exportProbeMenu.modalPresentationStyle = .formSheet
            self.present(exportProbeMenu, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad(){
    super.viewDidLoad()
     //   probeChrtSampleRate.stepValue = 2
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
      //  exportDomeChrtMenu()
        probeChrtSmplLbl.textAlignment = NSTextAlignment.center
        probeChrtSmplLbl.text = String(probeChrtSamplePerMinInt)
        probeChrtSmplLbl.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 36  )
        probeChrtSmplLbl.backgroundColor = UIColor.black
        probeChrtSmplLbl.textColor = UIColor.white
        self.view.addSubview(probeChrtSmplLbl)
        
        ProbeChrtLabel.textAlignment = NSTextAlignment.center
        ProbeChrtLabel.text = "Enter Probe Chart Log File \n" + "Sample Rate (sample per minute)"
        ProbeChrtLabel.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 12    )
        ProbeChrtLabel.backgroundColor = UIColor.black
        ProbeChrtLabel.textColor = UIColor.white
        self.view.addSubview(ProbeChrtLabel)
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
 
}
