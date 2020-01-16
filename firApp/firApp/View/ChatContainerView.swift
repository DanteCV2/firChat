//
//  ChatContainerView.swift
//  firApp
//
//  Created by Dante Cervantes Vega on 16/01/20.
//  Copyright © 2020 Dante Cervantes Vega. All rights reserved.
//

import UIKit

class ChatContainerView: UIView, UITextFieldDelegate {
    
    var chtaVC : ChatViewController? {
        didSet{
            sendButton.addTarget(chtaVC, action: #selector(ChatViewController.sendMessage), for: .touchUpInside)
            updImage.addGestureRecognizer(UITapGestureRecognizer(target: chtaVC, action: #selector(ChatViewController.handleUploadTap)))
        }
    }
    
    lazy var messageTextField : UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter mesage..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    let updImage: UIImageView = {
        let updImage = UIImageView()
        updImage.isUserInteractionEnabled = true
        updImage.image = UIImage(systemName: "camera.circle.fill")
        updImage.translatesAutoresizingMaskIntoConstraints = false
        return updImage
    }()
    
    let sendButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
                        
        addSubview(updImage)
        
        updImage.leftAnchor.constraint(equalTo:leftAnchor).isActive = true
        updImage.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        updImage.widthAnchor.constraint(equalToConstant: 44).isActive = true
        updImage.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sendButton)
        
        sendButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        addSubview(messageTextField)
        
        messageTextField.leftAnchor.constraint(equalTo: updImage.rightAnchor, constant: 8).isActive = true
        messageTextField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        messageTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        messageTextField.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(red: 220.0/255.0, green: 220.0/255.0, blue: 220.0/255.0, alpha: 1)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorLineView)
        
        separatorLineView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
