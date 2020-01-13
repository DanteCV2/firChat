//
//  UserCell.swift
//  firApp
//
//  Created by Dante Cervantes Vega on 03/01/20.
//  Copyright © 2020 Dante Cervantes Vega. All rights reserved.
//

import UIKit
import Firebase

class UserCell: UITableViewCell {
    
    var message : Message? {
        didSet{
            
            fetchUserMessageInfo()
            detailTextLabel?.text = message?.text
            
            if let seconds = message?.timeStamp?.doubleValue{
                let timeDate = NSDate(timeIntervalSince1970: seconds)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm:ss a"
                timeLabel.text = dateFormatter.string(from: timeDate as Date)
            }
        }
    }
    
    private func fetchUserMessageInfo(){
        
       
        
        if let id = message?.partenerId() {
            Database.database().reference().child("users").child(id).observeSingleEvent(of: .value) { (snapshot) in
                
                if let dictionary = snapshot.value as? [String : String]{
                    self.textLabel?.text = dictionary["name"]
                    
                    if let profileImageUrl = dictionary["profileImageUrl"] {
                        self.profileImageView.loadImageUsignCacheWithUrlString(urlString: profileImageUrl)
                    }
                }
            }
        }
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSubviews()
        textLabel?.frame = CGRect(x: 64, y: textLabel!.frame.origin.y - 2, width: textLabel!.frame.width, height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: 64, y: detailTextLabel!.frame.origin.y + 2, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
    }
    
    let profileImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let timeLabel : UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        addSubview(timeLabel)
        
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 18).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: textLabel!.heightAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
