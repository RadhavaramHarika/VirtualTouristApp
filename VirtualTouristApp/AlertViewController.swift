//
//  AlertViewController.swift
//  VirtualTouristApp
//
//  Created by radhavaram harika on 1/18/17.
//  Copyright © 2017 Practise. All rights reserved.
//

import UIKit

class AlertViewController: UIAlertController {

    func displayAlertView(viewController controller:UIViewController,alertTitle title:String,alertMessage message:String){
        
        let alert = UIAlertController(title:title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style:UIAlertActionStyle.cancel, handler: nil))
        controller.present(alert, animated: true, completion: nil)
    }

}
