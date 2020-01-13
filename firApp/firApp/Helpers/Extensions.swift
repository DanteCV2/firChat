//
//  Extensions.swift
//  firApp
//
//  Created by Dante Cervantes Vega on 02/01/20.
//  Copyright © 2020 Dante Cervantes Vega. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImageUsignCacheWithUrlString(urlString : String){
        
        self.image = nil
        
        if let cacheImage = imageCache.object(forKey: urlString as AnyObject){
            self.image = cacheImage as? UIImage
            return
        }
        
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            if error != nil{
                print(error!.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                
                if let downloadedImage = UIImage(data: data!){
                    imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    self.image = downloadedImage
                }
                
            }
        }).resume()
    }
}
