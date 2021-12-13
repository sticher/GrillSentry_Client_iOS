//
//  GraphingDomeTempView.swift
//  GrillSentry
//  handles only the GrillSentry DOME temp
//  Created by Ken Sticher on 7/14/21.
//  Copyright © 2021 Ken Sticher. All rights reserved.
//

import SwiftUI
import Foundation
import UIKit
import Charts
import TinyConstraints
import AVFoundation


class GraphTempView: UIViewController, ChartViewDelegate, UIDocumentPickerDelegate {
   
 //   var graphDomeflg = true
 //   var graphProbeflg = false
    
    var graphTimer: Timer?
   // var domeChartWndwSldFlg = false
    var date: String = ""
    
    
    @IBOutlet weak var domeChartLabel: UILabel!
    
    @IBOutlet var GraphTempScreen: BarLineChartViewBase!
    
    @IBOutlet weak var domeAlarmBttn: UIButton!
    
  
    @IBAction func cancelDomeTempAlrm(_ sender: Any) {
        
                domeAlarmBttn.isHidden = true
                domeAlrmTmpInt = 749
                domeAlrmIsArmd = false
     
    }
    
    @IBOutlet weak var screenShotBttn: UIButton!
    @IBOutlet weak var GraphTempEnd: UIButton!
    @IBAction func screenShotCapture(_ sender: Any) {
        takeScreenshot(of: lineChartView)
    }
    
    @IBAction func GraphTempStop(_ sender: Any) {
      //  domeChartWndwSldFlg = true
        graphTimer?.invalidate()
          self.dismiss(animated: true, completion: nil)
    }
   
    @IBOutlet weak var settingsDmeChrtBttn: UIButton!
    
  
    @IBAction func settingsDmeChrt(_ sender: Any) {
        let saveDomeChrtView = self.storyboard?.instantiateViewController(withIdentifier: "saveDomeCharttoDocuments") as! saveDomeChartToFileView
    
        self.present(saveDomeChrtView, animated: true, completion: nil)
        
    }
    
    @objc func domeGraphTempContinue() { // key function required to update the chart data
        setData()
        
    }
  
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let allowedCharacters = "+1234567890"
        let allowedCharacterSet = CharacterSet(charactersIn: allowedCharacters)
        let typedCharacterSet = CharacterSet(charactersIn: string)
        return allowedCharacterSet.isSuperset(of: typedCharacterSet)
    }
    
    let lineChartView: LineChartView = {
    let chartView = LineChartView()
        chartView.backgroundColor = .darkGray // UIColor(red:15, green: 141, blue:15, alpha: 0.5)

    chartView.rightAxis.enabled = false
    let yAxis = chartView.leftAxis
    yAxis.labelFont = .boldSystemFont(ofSize: 12)
    yAxis.setLabelCount(10, force: false)
    yAxis.labelTextColor = .green
    yAxis.axisLineColor = .green
   // yAxis.axisMaximum = 500.0
   // yAxis.axisMinimum = 50.0
    yAxis.drawTopYLabelEntryEnabled = true
    chartView.xAxis.labelPosition = .bottom
    chartView.xAxis.labelFont = .boldSystemFont(ofSize: 12)
    chartView.xAxis.setLabelCount(8, force: false)
    chartView.xAxis.labelTextColor = .green
    chartView.xAxis.axisLineColor = .green
        
    chartView.drawMarkers = true
    
    return chartView
    }()
  
    override func viewDidLoad(){
    super.viewDidLoad()
    // Do any additional setup after loading the view
    
        domeChartLabel.textAlignment = NSTextAlignment.center
        domeChartLabel.text = "Dome Temperature Chart"
        domeChartLabel.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 36  )
        domeChartLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.75)
        domeChartLabel.textColor = UIColor.green
        self.view.addSubview(domeChartLabel)
        
        domeAlarmBttn.isHidden = true
        view.backgroundColor = .black
        view.addSubview(lineChartView)
        lineChartView.centerInSuperview()
        lineChartView.width(to: view)
        lineChartView.heightToWidth(of: view)
        
        date = getDate2()
        
    graphTimer = Timer.scheduledTimer(timeInterval:  0.5, target: self, selector: #selector(domeGraphTempContinue), userInfo: nil, repeats: true)

}
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
      
        func chartValueSelected( chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
           // print (entry)
        }
    }
    
    func setData() {//setup the dome data chart using CocoaPod 'Charts' capability
       
        var entry = [ChartDataEntry]()
        let currentDomeTempValue = Double(domeTempArray[(domefileEntryTotalCount-1)])!
        
        if Int16(currentDomeTempValue) > domeAlrmTmpInt
        {
            domeAlarmBttn.isHidden = false
        }
        else
        {
            domeAlarmBttn.isHidden = true
        }
        
            for x in 0..<domefileEntryTotalCount
            
            {
                if Double(domeTempArray[Int(x)]) ?? 0 > 800.0
                 {
                    print("error here  \(domeTempArray[(x)])")
                 }
               entry.append(ChartDataEntry(x: Double(domechartMinuteCnt[Int(x)]), y:Double(domeTempArray[Int(x)]) ?? 0))
            }
     
        let yValues = entry
    
        let set1 = LineChartDataSet(entries: yValues, label: "DomeTemp(DegF) vs. Time(minutes)")
            set1.mode = .linear
            set1.drawCirclesEnabled = false
            set1.lineWidth = 3
            set1.setColor(.green)
            set1.fill = Fill(color: .green)
            set1.fillAlpha = 0.2
            set1.drawFilledEnabled = true
            set1.drawValuesEnabled = true
            set1.highlightEnabled = true
        
            let data = LineChartData(dataSet:set1)
        
            data.setDrawValues(false)
        
            lineChartView.data = data
        
            lineChartView.chartDescription?.text = "Dome Alarm Temp: \(domeAlrmTmpInt+1)F  " + " \(date)"
    }
        
    
    func getDocumentsDirectory() -> URL {
                // find all possible documents directories for this user
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                 // just send back the first one, which ought to be the only one
                return paths[0]
            }
        
    // MARK: - Actions to save Dome Graph screenshot to file
    
      @objc func imageWasSaved(_ image: UIImage, error: Error?, context: UnsafeMutableRawPointer) {
          if let error = error {
              print(error.localizedDescription)
              return

          }

          print("Image was saved in the photo gallery/n/n/n")
     //     UIApplication.shared.open(URL(string:"photos-redirect://")!)
      }
    
    
    func takeScreenshot(of view: UIView) {
          UIGraphicsBeginImageContextWithOptions(
              CGSize(width: view.bounds.width, height: view.bounds.height),
              false,
              2
          )
        
            view.layer.render(in: UIGraphicsGetCurrentContext()!)
                let screenshot = UIGraphicsGetImageFromCurrentImageContext()!
                  UIGraphicsEndImageContext()

            let data = screenshot.pngData()!
            let filename = getDocumentsDirectory().appendingPathComponent("DomeChartTotalImage.png")
            try? data.write(to: filename)
            print("write DomeChartTotalImage.png")
     //       UIImageWriteToSavedPhotosAlbum(screenshot, self, #selector(imageWasSaved), nil)
            UIImageWriteToSavedPhotosAlbum(screenshot, self, #selector(imageWasSaved), nil)
            }
        
        //       UIImageWriteToSavedPhotosAlbum(screenshot, self, #selector(imageWasSaved), nil)
            
    func getDate2() -> String {
    
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
    

}

extension GraphTempView: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let AlarmString = textField.text {
            domeAlrmTmpInt = Int(AlarmString) ?? 0
            domeAlrmTmpInt = (domeAlrmTmpInt - 1)
            domeAlrmIsArmd = true
        }
        return true}
}
