//
//  SettingsPopoverViewController.swift
//  EggZact
//
//  Created by Steven Osborne on 11/15/17.
//  Copyright © 2017 Ken Sticher. All rights reserved.
//

import UIKit

class SettingsPopoverViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func dismiss(sender: AnyObject) {
        self.dismiss(animated:true, completion: nil)
    }
}
