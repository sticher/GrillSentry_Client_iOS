//
//  ProbeGraphTempView.swift
//  GrillSentry
//
//  Created by Ken Sticher on 8/4/21.
//  Copyright © 2021 Ken Sticher. All rights reserved.
//

import Foundation
import UIKit
import Charts
import TinyConstraints
import AVFoundation

class probeGraphView: UIViewController, ChartViewDelegate {
    var graphTimer: Timer?
  //  var probeChartWndwSldFlg = false
    var date: String = ""
 
    
    @IBOutlet weak var foodProbeChrtLabel: UILabel!
   
    @IBOutlet var probeChartScreen: BarLineChartViewBase!
    
    @IBOutlet weak var probeAlarmBttn: UIButton!
    
    @IBAction func cancelProbeAlarm(_ sender: Any) {
        probeAlarmBttn.isHidden = true
        probeAlrmTmpInt = 499
        probeAlrmIsArmd = false
        
    }
    
    @IBOutlet weak var screenShotProbeChrtBttn: UIButton!
    @IBAction func screenshotProbeChrt(_ sender: Any) {
        takeScreenshot(of: lineChartView)    }
    
    @IBOutlet weak var settingsProbeChrtBttn: UIButton!
    
    @IBAction func settingsProbeChrt(_ sender: Any) {
        
            let saveProbeChrtView = self.storyboard?.instantiateViewController(withIdentifier: "saveProbeCharttoDocuments") as! saveProbeChartToFileView
    
        self.present(saveProbeChrtView, animated: true, completion: nil)
   
    }
    
    @IBOutlet weak var probeChartEnd: UIButton!
  
    @IBAction func probeChartEnd(_ sender: Any)
    {
   //     probeChartWndwSldFlg = true
        graphTimer?.invalidate()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    @objc func probeGraphTempContinue() { // key function required to update the
        
        setDataProbe()
    }
    
    
    var lineChartView: LineChartView = {
    var chartView = LineChartView()
    //chartView.backgroundColor = .systemBlue
    chartView.backgroundColor = .darkGray //UIColor(red:00, green: 205, blue:210, alpha: 0.5)
    chartView.rightAxis.enabled = false
    let yAxis = chartView.leftAxis
    yAxis.labelFont = .systemFont(ofSize: 12)
    yAxis.setLabelCount(10, force: false)
    yAxis.labelTextColor = UIColor(red:00, green: 205, blue:210, alpha: 0.5)
        //green
     yAxis.axisLineColor = .white
 
    yAxis.drawTopYLabelEntryEnabled = true
    chartView.xAxis.labelPosition = .bottom
    chartView.xAxis.labelFont = .systemFont(ofSize: 12)
    chartView.xAxis.setLabelCount(8, force: false)
    chartView.xAxis.labelTextColor = UIColor(red:00, green: 205, blue:210, alpha: 0.5)
    chartView.xAxis.axisLineColor = .white
     
    chartView.drawMarkers = true
    
    return chartView
    }()
    
    override func viewDidLoad(){
    super.viewDidLoad()
    // Do any additional setup after loading the view
        
        foodProbeChrtLabel.textAlignment = NSTextAlignment.center
        foodProbeChrtLabel.text = "Food Probe Temperature Chart"
        foodProbeChrtLabel.font = UIFont(name: "LiquidCrystal-ExtraBold", size: 36  )
        foodProbeChrtLabel.backgroundColor = UIColor(red: 0, green: 205, blue: 210.0, alpha: 0.5)
        foodProbeChrtLabel.textColor = UIColor.white
        self.view.addSubview(foodProbeChrtLabel)
        
        
        probeAlarmBttn.isHidden = true
        view.backgroundColor = .black
        view.addSubview(lineChartView)
        lineChartView.centerInSuperview()
        lineChartView.width(to: view)
        lineChartView.heightToWidth(of: view)
        
        date = getDate()
        

        graphTimer = Timer.scheduledTimer(timeInterval:  0.5, target: self, selector: #selector(probeGraphTempContinue), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
        
    }
  
    @objc func chartValueSelected( chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
           // print (entry)
    }
    
    @objc func setDataProbe() {//setup the Probe Data chart using CocoaPod 'Charts' capability
        
        var entry = [ChartDataEntry]()
        
        let currentProbeTempValue = Double(probeTempArray[(probefileEntryTotalCount-1)])!      //  var get = [Double] ()
        if Int16(currentProbeTempValue) > probeAlrmTmpInt
        {
            probeAlarmBttn.isHidden = false
        }
        else
        {
            probeAlarmBttn.isHidden = true
        }
      //  for x in 0..<fileEntryTotalCount //fileEntryTotalCount is the total# of array elements
   //     if probeChartWndwSldFlg == false
     //   {
            for x in 0..<probefileEntryTotalCount
            {
            entry.append(ChartDataEntry(x: Double(probechartMinuteCnt[Int(x)]), y: Double(probeTempArray[Int(x)]) ?? 0))
            }
     /*   }
        else
        {
            if probefileEntryTotalCount<(probeSlidingWindowCnt+1) {
  
                for x in (probefileEntryTotalCount - probefileEntryTotalCount)..<probefileEntryTotalCount
                {
                entry.append(ChartDataEntry(x: Double(probechartMinuteCnt[Int(x)]), y: Double(probeTempArray[Int(x)]) ?? 0))
                }
            }
            else
            {
            for x in (probefileEntryTotalCount-probeSlidingWindowCnt)..<probefileEntryTotalCount
                {
               entry.append(ChartDataEntry(x: Double(probechartMinuteCnt[Int(x)]), y: Double(probeTempArray[Int(x)]) ?? 0))
                }
            }
        }
     */
        let yValues = entry
        
          //  print("ChartDataEntries \(entry)")
    
        let set1 = LineChartDataSet(entries: yValues, label: "FoodProbeTemp(DegF) vs Time(minutes)")
        
            set1.mode = .linear
            set1.drawCirclesEnabled = false
            set1.lineWidth = 3
            set1.setColor(.white)
        //    set1.fill = Fill(color: .white)
         //   set1.fill = Fill(color: UIColor(red:00, green: 205, blue:210, alpha: 0.20 ))
       //     set1.fillAlpha = 0.2
            set1.drawFilledEnabled = true
            set1.drawValuesEnabled = true
            set1.highlightEnabled = true
        
            let data = LineChartData(dataSet:set1)
        
            data.setDrawValues(false)
        
            lineChartView.data = data
        
            lineChartView.chartDescription?.text = "Probe Alarm Temp: \(probeAlrmTmpInt+1)F  " + " \(date)"
        
    }
    
    // MARK: - Actions to save Probe Graph screenshot to file
    
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
            let filename = getDocumentsDirectory().appendingPathComponent("ProbeChartTotalImage.png")
            try? data.write(to: filename)
            print("write ProbeChartTotalImage.png")
     //       UIImageWriteToSavedPhotosAlbum(screenshot, self, #selector(imageWasSaved), nil)
            UIImageWriteToSavedPhotosAlbum(screenshot, self, #selector(imageWasSaved), nil)
            }
        
        //       UIImageWriteToSavedPhotosAlbum(screenshot, self, #selector(imageWasSaved), nil)
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
         // just send back the first one, which ought to be the only one
        return paths[0]
    }
    
    func getDate() -> String {
    
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
