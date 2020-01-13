//
//  ChatMessengerCell.swift
//  firApp
//
//  Created by Dante Cervantes Vega on 06/01/20.
//  Copyright © 2020 Dante Cervantes Vega. All rights reserved.
//

import UIKit

class ChatMessengerCell: UICollectionViewCell {
    
    let textView: UITextView = {
        let txt = UITextView()
        txt.text = "Dummy text"
        txt.font = .systemFont(ofSize: 16)
        txt.translatesAutoresizingMaskIntoConstraints = false
        txt.backgroundColor = .clear
        txt.textColor = .white
        
        return txt
    }()
    
    static let blueBubbleClor = UIColor(red: 0.0/255.0, green: 137.0/255.0, blue: 249.0/255.0, alpha: 1)
    static let grayBubbleColor = UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1)
    
    let bubbleView : UIView = {
        let view = UIView()
        view.backgroundColor = blueBubbleClor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
    let profileImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person")
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }()
    
    var bubbleWidthAnchor : NSLayoutConstraint?
    var bubbleRightAnchor : NSLayoutConstraint?
    var bubbleLeftAnchor : NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bubbleView)
        addSubview(textView)
        addSubview(profileImageView)
        
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        bubbleRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        bubbleRightAnchor?.isActive = true
        bubbleLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
        //bubbleLeftAnchor?.isActive = false
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleWidthAnchor?.isActive = true
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8).isActive = true
        textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
        textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
