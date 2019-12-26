//
//  CustomAlertView.swift
//  CustomAlertView
//
//  Created by Daniel Luque Quintana on 16/3/17.
//  Copyright © 2017 dluque. All rights reserved.
//
import UIKit

class CustomAlertView: UIViewController {
    
    @IBOutlet weak var versionLabel:     UILabel!
    @IBOutlet weak var batteryLabel:     UILabel!
    @IBOutlet weak var alertView:        UIView!
    @IBOutlet weak var closeButton:      UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var unitSelector:     UISegmentedControl!
    
    var delegate: CustomAlertViewDelegate?
    var selectedOption = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupView()
        animateView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layoutIfNeeded()
        closeButton.layer.borderWidth = 1
    }
    
    func setupView() {
        alertView.layer.cornerRadius = 15
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    }
    
    func animateView() {
        alertView.alpha = 0;
        self.alertView.frame.origin.y = self.alertView.frame.origin.y + 50
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            self.alertView.alpha = 1.0;
            self.alertView.frame.origin.y = self.alertView.frame.origin.y - 50
        })
    }
    
    @IBAction func onTapCloseButton(_ sender: Any) {
        delegate?.closeButtonTapped()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onTapDisconnectButton(_ sender: Any) {
        delegate?.disconnectButtonTapped()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onTapSegmentedControl(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            print("Celcius")
            selectedOption = "°C"
            delegate?.changeUnits(selectedOption: selectedOption)
            break
        case 1:
            print("Fahrenheit")
            selectedOption = "°F"
            delegate?.changeUnits(selectedOption: selectedOption)
            break
        default:
            break
        }
    }
    
    @IBAction func CalON(_ sender: Any)
    { delegate?.CalON() }
    
    @IBAction func CalOFF(_ sender: Any)
    { delegate?.CalOFF() }
    
    @IBAction func VrefUP(_ sender: Any)
    { delegate?.VrefUP() }
    
    @IBAction func VrefDOWN(_ sender: Any)
    { delegate?.VrefDOWN() }
    
}

@IBDesignable extension UIButton {
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}
