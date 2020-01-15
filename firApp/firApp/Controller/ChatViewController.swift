//
//  ChatCollectionViewController.swift
//  firApp
//
//  Created by Dante Cervantes Vega on 02/01/20.
//  Copyright © 2020 Dante Cervantes Vega. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var user : User? {
        didSet{
            navigationItem.title = user?.name
            observeMessages()
        }
    }
    
    let reuseIdentifier = "Cell"
    var messages = [Message]()
    var containerViewBottomAnchor : NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        self.collectionView!.register(ChatMessengerCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.backgroundColor = .white
        self.collectionView.keyboardDismissMode = .interactive
        setKeyBoardManager()
    }
    
    override var inputAccessoryView: UIView?{
        get{
            return inputContainer
        }
    }
    
    override var canBecomeFirstResponder: Bool {return true}
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func observeMessages(){
        
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
            return
        }
        
        let ref = Database.database().reference().child("user-messages").child(uid).child(toId)
        ref.observe(.childAdded) { (snapshot) in
            let msgId = snapshot.key
            let msgRef = Database.database().reference().child("messages").child(msgId)
            msgRef.observeSingleEvent(of: .value) { (snapshot) in
                guard let dictionary = snapshot.value as? [String : AnyObject] else {
                    return
                }
                
                self.messages.append(Message(dictionary: dictionary))
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                }
            }
        }
    }
    
    @objc func handleUploadTap(){
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc func sendMessage(){
        let properties = ["text" : messageTextField.text!] as [String : AnyObject]
        sendMessageWithProperties(properties: properties)
    }
    
    // MARK: -UICollectionViewDataSource
    
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
        if let text = message.text{
            cell.bubbleWidthAnchor?.constant = estimatedFrameForTExt(text: text).width + 32
        }else if message.imageUrl != nil{
            cell.bubbleWidthAnchor?.constant = 200
        }
        return cell
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height : CGFloat = 80
        let message = messages[indexPath.item]
        
        if let text = message.text{
            height = estimatedFrameForTExt(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue{
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    private func estimatedFrameForTExt(text : String) -> CGRect{
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    //MARK: -View Methods
    
    let messageTextField : UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter mesage..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    lazy var inputContainer: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height:85)
        containerView.backgroundColor = .white
        
        let updImage = UIImageView()
        updImage.isUserInteractionEnabled = true
        updImage.image = UIImage(systemName: "camera.circle.fill")
        updImage.translatesAutoresizingMaskIntoConstraints = false
        updImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
        containerView.addSubview(updImage)
        
        updImage.leftAnchor.constraint(equalTo:containerView.leftAnchor).isActive = true
        updImage.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        updImage.widthAnchor.constraint(equalToConstant: 44).isActive = true
        updImage.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
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
        
        messageTextField.leftAnchor.constraint(equalTo: updImage.rightAnchor, constant: 8).isActive = true
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
        
        return containerView
    }()
    
    func setKeyBoardManager(){
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillApperar), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisapear), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleKeyboardDidShow(){
        if messages.count > 0{
            let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
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
        
        if let messageImageUrl = message.imageUrl{
            cell.messageImageView.loadImageUsignCacheWithUrlString(urlString: messageImageUrl)
        }
    }
}

extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        var selectedImageFromPicker : UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        }else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseUsingImage(image: selectedImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func uploadToFirebaseUsingImage(image : UIImage){
        
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = image.jpegData(compressionQuality: 0.2){
            ref.putData(uploadData, metadata: nil) { (metadata, error) in
                
                if error != nil{
                    self.showAlert(message: error!.localizedDescription)
                    return
                }
                
                ref.downloadURL { (url, error) in
                    
                    if error != nil{
                        self.showAlert(message: error!.localizedDescription)
                        return
                    }
                    
                    if let imageUrl = url?.absoluteString{
                        self.sendMessageWithImage(imageUrl: imageUrl, image: image)
                    }
                }
            }
        }
    }
    
    func sendMessageWithImage(imageUrl : String, image : UIImage){
        let properties = ["imageUrl" : imageUrl, "imageWidth" : image.size.height, "imageHeight": image.size.height] as [String : AnyObject]
       sendMessageWithProperties(properties: properties)
    }
    
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    private func sendMessageWithProperties(properties: [String : AnyObject]){
        
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = Auth.auth().currentUser!.uid
        let timeStamp : NSNumber = NSNumber(value: Int(NSDate().timeIntervalSince1970))
        var values = [ "toId" : toId, "fromId": fromId, "timeStamp" : timeStamp] as [String : Any]
        
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { (error, ref) in
            
            if error != nil{
                self.showAlert(message: error!.localizedDescription)
                return
            }
            
            self.messageTextField.text = nil
            
            let userMessageRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            let messageId = [childRef.key : 1]
            
            userMessageRef.updateChildValues(messageId)
            
            let recipientUserMessRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessRef.updateChildValues(messageId)
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
