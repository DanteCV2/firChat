//
//  ChatCollectionViewController.swift
//  firApp
//
//  Created by Dante Cervantes Vega on 02/01/20.
//  Copyright © 2020 Dante Cervantes Vega. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout,UITextFieldDelegate {
    
    var user : User? {
        didSet{
            navigationItem.title = user?.name
            observeMessages()
        }
    }
    
    let cellId = "cellId"
    var messages = [Message]()
    var containerViewBottomAnchor : NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        self.collectionView!.register(ChatMessengerCell.self, forCellWithReuseIdentifier: cellId)
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
    
    //MARK: -Firebase Methods
    
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
    
    @objc func sendMessage(){
        let properties = ["text" :inputContainer.messageTextField.text!] as [String : AnyObject]
        sendMessageWithProperties(properties: properties)
    }
    
    func sendMessageWithImage(imageUrl : String, image : UIImage){
        let properties = ["imageUrl" : imageUrl, "imageWidth" : image.size.height, "imageHeight": image.size.height] as [String : AnyObject]
        sendMessageWithProperties(properties: properties)
    }
    
    private func uploadToFirebaseUsingImage(image : UIImage, completion: @escaping (_ imageUrl: String) -> ()){
        
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
                        completion(imageUrl)
                    }
                }
            }
        }
    }
    
    private func uploadToFireBaseUsingVideoUrl(url : URL){
        
        let fileName = UUID().uuidString + ".mov"
        let ref = Storage.storage().reference().child("message_videos").child(fileName)
        
        let task = ref.putFile(from: url, metadata: nil) { (_, error) in
            if error != nil{
                self.showAlert(message: error!.localizedDescription)
                return
            }
            
            ref.downloadURL { (downloadUrl, error) in
                if error != nil{
                    self.showAlert(message: error!.localizedDescription)
                    return
                }
                
                 guard let downloadUrl = downloadUrl else { return }
                
                if let thumbnailImage = self.thumbnailImageForVideoUrl(url: url){
                    self.uploadToFirebaseUsingImage(image: thumbnailImage) { (imageUrl) in
                        let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": thumbnailImage.size.width as AnyObject, "imageHeight": thumbnailImage.size.height as AnyObject, "videoUrl": downloadUrl as AnyObject]
                        self.sendMessageWithProperties(properties: properties)
                    }
                }
            }
        }
        
        task.observe(.progress) { (snapshot) in
            if let progress = snapshot.progress?.completedUnitCount{
                self.navigationItem.title = String(progress)
            }
        }
        
        task.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
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
            
            self.inputContainer.messageTextField.text = nil
            
            let userMessageRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            let messageId = [childRef.key : 1]
            
            userMessageRef.updateChildValues(messageId)
            
            let recipientUserMessRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            recipientUserMessRef.updateChildValues(messageId)
        }
    }
    
    // MARK: -UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessengerCell
        cell.chatVC = self
        // Configure the cell
        let message = messages[indexPath.item]
        cell.message = message
        
        cell.textView.text = message.text
        setupCell(cell: cell, message: message)
        
        if let text = message.text{
            cell.bubbleWidthAnchor?.constant = estimatedFrameForTExt(text: text).width + 32
            cell.textView.isHidden = false
        } else if message.imageUrl != nil{
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
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
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsignCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
        } else {
            cell.messageImageView.isHidden = true
        }
    }
    
    //MARK: -View Methods
    
    lazy var inputContainer: ChatContainerView = {
        
        let chatConatinerView = ChatContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height:85))
        chatConatinerView.chtaVC = self
        return chatConatinerView
    }()
    
    private func thumbnailImageForVideoUrl(url : URL) -> UIImage?{
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do{
             let thumbnailCgImage = try imageGenerator.copyCGImage(at: CMTime(value: 1, timescale: 60), actualTime: nil)
             return UIImage(cgImage:thumbnailCgImage)
        } catch let error {
            showAlert(message: error.localizedDescription)
        }
        return nil
    }
    
    func setKeyBoardManager(){
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
    }
    
    @objc func handleKeyboardDidShow(){
        if messages.count > 0{
            let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    @objc func handleUploadTap(){
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        //Uncomment this line to continue with video implementation
        //imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        present(imagePickerController, animated: true, completion: nil)
    }
    
    var startingFrame : CGRect?
    var zoomBackgroud : UIView?
    var startingImageView : UIImageView?
    
    func performZoom(startingImageView: UIImageView){
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.backgroundColor = .red
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(performZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow{
            
            zoomBackgroud = UIView(frame: keyWindow.frame)
            zoomBackgroud?.backgroundColor = .black
            zoomBackgroud?.alpha = 0
            keyWindow.addSubview(zoomBackgroud!)
            
            let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0,usingSpringWithDamping: 1,initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.zoomBackgroud?.alpha = 1
                self.inputContainer.alpha = 0
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
            }, completion: nil)
        }
    }
    
    @objc func performZoomOut(tapGesture : UITapGestureRecognizer){
        if let zoomOutImageView = tapGesture.view{
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            UIView.animate(withDuration: 0.5, delay: 0,usingSpringWithDamping: 1,initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                zoomOutImageView.frame = self.startingFrame!
                self.zoomBackgroud?.alpha = 0
                self.inputContainer.alpha = 1
            }) { (completed) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            }
        }
    }
}

extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                
        if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL{
            uploadToFireBaseUsingVideoUrl(url: videoUrl)
        }else{
            handleSelectedImageFromPicker(info: info)
        }
        dismiss(animated: true, completion: nil)
    }
    
    private func handleSelectedImageFromPicker(info : [UIImagePickerController.InfoKey : Any]){
        
        var selectedImageFromPicker : UIImage?
        
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] {
            selectedImageFromPicker = editedImage as? UIImage
        }else if let originalImage = info[UIImagePickerController.InfoKey.originalImage]  {
            selectedImageFromPicker = originalImage as? UIImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseUsingImage(image: selectedImage) { (imageUrl) in
                self.sendMessageWithImage(imageUrl: imageUrl, image: selectedImage)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
