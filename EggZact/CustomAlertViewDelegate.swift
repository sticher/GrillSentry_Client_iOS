//
//  CustomAlertViewDelegate.swift
//  CustomAlertView
//
//  Created by Daniel Luque Quintana on 16/3/17.
//  Copyright © 2017 dluque. All rights reserved.
//
protocol CustomAlertViewDelegate: class {
    func disconnectButtonTapped()
    func closeButtonTapped()
    func changeUnits(selectedOption: String)
    func CalON()
    func CalOFF()
    func VrefUP()
    func VrefDOWN()
}
