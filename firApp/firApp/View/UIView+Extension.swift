//
//  UIView+Extension.swift
//  firApp
//
//  Created by Dante Cervantes Vega on 30/12/19.
//  Copyright © 2019 Dante Cervantes Vega. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    
    func setGrandientBackground(){
        
        let gradientLayer = CAGradientLayer()
        
        let colorTop = UIColor(red: 137.0/255.0, green: 247.0/255.0, blue: 254.0/255.0, alpha: 1).cgColor
        let colorBottom = UIColor(red: 102.0/255.0, green: 166.0/255.0, blue: 255.0/255.0, alpha: 1).cgColor
        
        gradientLayer.frame = bounds
        gradientLayer.colors = [colorTop,colorBottom]
        gradientLayer.locations = [0.0,1.0]
        gradientLayer.startPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.0)
        
        layer.insertSublayer(gradientLayer, at: 0)
    }
}

extension UIViewController {
    func showAlert( message : String){
        let alert = UIAlertController(title: "Something went wrong", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        self.show(alert, sender: nil)
    }
}
