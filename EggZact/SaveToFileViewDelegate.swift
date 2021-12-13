//
//  SaveToFileViewDelegate.swift
//  GrillSentry
//
//  Created by Ken Sticher on 8/17/21.
//  Copyright © 2021 Ken Sticher. All rights reserved.
//

import Foundation
import UIKit

protocol SaveToFileViewDelegate: AnyObject {
    /*
    func disconnectButtonTapped()
    func closeButtonTapped()
    func changeUnits(selectedOption: String)
    func CalON()
    func CalOFF()
    func VrefUP()
    func VrefDOWN()
    func EnableCalibration()
*/
    func getDocumentsDirectory() -> URL
    func setFileToDocumentsFolder(nameForFile: String, extForFile: String) -> URL
}
