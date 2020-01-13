//
//  ChatCollectionViewController.swift
//  firApp
//
//  Created by Dante Cervantes Vega on 02/01/20.
//  Copyright © 2020 Dante Cervantes Vega. All rights reserved.
//

import UIKit
import Firebase

private let reuseIdentifier = "Cell"

class ChatViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var user : User? {
        didSet{
            navigationItem.title = user?.name
            observeMessages()
        }
    }
    
    var messages = [Message]()
    
    let messageTextField : UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter mesage..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register cell classes
        self.collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        self.collectionView!.register(ChatMessengerCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView.alwaysBounceVertical = true
        
        setView()
        collectionView.backgroundColor = .white
        //setKeyBoardManager()
        collectionView.keyboardDismissMode = .interactive
    }
    
    override var canBecomeFirstResponder: Bool {return true}
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func setKeyBoardManager(){
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillApperar), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisapear), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillApperar(notification : Notification){
        
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let cgValue = keyboardFrame.cgRectValue
            containerViewBottomAnchor?.constant = -cgValue.height
        }
        
        if let keyboardDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSString {
            let kDuration =  keyboardDuration.doubleValue
            UIView.animate(withDuration: kDuration) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func keyboardWillDisapear(notification : Notification){
        containerViewBottomAnchor?.constant = 0
        if let keyboardDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSString {
            let kDuration =  keyboardDuration.doubleValue
            UIView.animate(withDuration: kDuration) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func observeMessages(){
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded) { (snapshot) in
            let msgId = snapshot.key
            let msgRef = Database.database().reference().child("messages").child(msgId)
            msgRef.observeSingleEvent(of: .value) { (snapshot) in
                guard let dictionary = snapshot.value as? [String : AnyObject] else {
                    return
                }
                
                let message = Message()
                message.fromId = dictionary["fromId"] as? String
                message.text = dictionary["text"] as? String
                message.timeStamp = dictionary["timeStamp"] as? NSNumber
                message.toId = dictionary["toId"] as? String
                
                if message.partenerId() == self.user?.id{
                    self.messages.append(message)
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    var containerViewBottomAnchor : NSLayoutConstraint?
    
    func setView(){
        
        self.tabBarController?.tabBar.isHidden = true
        
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerViewBottomAnchor?.isActive = true
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        containerView.addSubview(sendButton)
        
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        containerView.addSubview(messageTextField)
        
        messageTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        messageTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        messageTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        messageTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor(red: 220.0/255.0, green: 220.0/255.0, blue: 220.0/255.0, alpha: 1)
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    @objc func sendMessage(){
        
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = Auth.auth().currentUser!.uid
        let timeStamp : NSNumber = NSNumber(value: Int(NSDate().timeIntervalSince1970))
        let values = ["text" : messageTextField.text!, "toId" : toId, "fromId": fromId, "timeStamp" : timeStamp] as [String : Any]
        childRef.updateChildValues(values) { (error, ref) in
            
            if error != nil{
                self.showAlert(message: error!.localizedDescription)
                return
            }
            
            self.messageTextField.text = nil
            
            let userMessageRef = Database.database().reference().child("user-messages").child(fromId)
            let messageId = [childRef.key : 1]
            
            userMessageRef.updateChildValues(messageId)
            
            let recipientUserMessRef = Database.database().reference().child("user-messages").child(toId)
            recipientUserMessRef.updateChildValues(messageId)
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ChatMessengerCell
        // Configure the cell
        let message = messages[indexPath.row]
        cell.textView.text = message.text
        setupCell(cell: cell, message: message)
        cell.bubbleWidthAnchor?.constant = estimatedFrameForTExt(text: message.text!).width + 32
        return cell
    }
    
    private func setupCell(cell : ChatMessengerCell, message : Message){
        
        if let profileImageUrl = self.user?.profileImageUrl{
            cell.profileImageView.loadImageUsignCacheWithUrlString(urlString: profileImageUrl)
        }
        
        if message.fromId == Auth.auth().currentUser?.uid{
            cell.bubbleView.backgroundColor = ChatMessengerCell.blueBubbleClor
            cell.textView.textColor = .white
            cell.profileImageView.isHidden = true
            cell.bubbleRightAnchor?.isActive = true
            cell.bubbleLeftAnchor?.isActive = false
        }else{
            cell.bubbleView.backgroundColor = ChatMessengerCell.grayBubbleColor
            cell.textView.textColor = .black
            cell.bubbleRightAnchor?.isActive = false
            cell.bubbleLeftAnchor?.isActive = true
            cell.profileImageView.isHidden = false
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height : CGFloat = 80
        if let text = messages[indexPath.item].text{
            height = estimatedFrameForTExt(text: text).height + 20
        }
        
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    private func estimatedFrameForTExt(text : String) -> CGRect{
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
}
