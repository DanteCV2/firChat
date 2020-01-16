//
//  ChatsViewController.swift
//  firApp
//
//  Created by Dante Cervantes Vega on 01/01/20.
//  Copyright © 2020 Dante Cervantes Vega. All rights reserved.
//

import UIKit
import Firebase

class ChatsList: UITableViewController {
    
    var messages = [Message]()
    var messageDict = [String : Message]()
    let cellId = "cellId"
    var timer  : Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(handleLogOut))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(handleNewMessage))
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        tableView.allowsMultipleSelectionDuringEditing = true
        checkIfUserIsLogged()
    }
    
    func checkIfUserIsLogged(){
        
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogOut), with: nil, afterDelay: 0)
        } else {
            fetchUserAndSetUpNavBarTitle()
        }
    }
    
    //MARK: - View
    func fetchUserAndSetUpNavBarTitle(){
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value) { (snapshot) in                
            if let dictionary = snapshot.value as? [String : String]{
                self.navigationItem.title = dictionary["name"]
                let user = User()
                user.name = dictionary["name"]
                user.profileImageUrl = dictionary["profileImageUrl"]
                user.email = dictionary["email"]
                self.setupNavbarWithUser(user: user)
            }
        }
    }
    
    
    @objc func handleReloadData(){
        self.messages = Array(self.messageDict.values)
        self.messages.sort { (m1, m2) -> Bool in
            return m1.timeStamp!.intValue > m2.timeStamp!.intValue
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func observeUserMessages(){
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference().child("user-messages").child(uid)
        
        ref.observe(.childAdded) { (snapshot) in
            
            let userId = snapshot.key
            Database.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded) { (snapshot) in
                
                let messageId = snapshot.key
                self.fetchMessage(messageId: messageId)
            }
            
        }
        
        ref.observe(.childRemoved) { (snapshot) in
            self.messageDict.removeValue(forKey: snapshot.key)
            self.reload()
        }
    }
    
    private func fetchMessage(messageId : String){
        let messageRef = Database.database().reference().child("messages").child(messageId)
        
        messageRef.observe(.value) { (snapshot) in
            
            let messageId = snapshot.key
            
            let messageRef = Database.database().reference().child("messages").child(messageId)
            
            messageRef.observeSingleEvent(of: .value) { (snapshot) in
                if let dictionary = snapshot.value as? [String : AnyObject]{
                    
                    let message = Message(dictionary: dictionary)
                    message.fromId = dictionary["fromId"] as? String
                    message.text = dictionary["text"] as? String
                    message.timeStamp = dictionary["timeStamp"] as? NSNumber
                    message.toId = dictionary["toId"] as? String
                    //self.messages.append(message)
                    
                    if let partnerId = message.partenerId(){
                        self.messageDict[partnerId] = message
                    }
                    self.reload()
                }
            }
            
        }
    }
    
    private func reload(){
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.handleReloadData), userInfo: nil, repeats: false)
    }
    
    func setupNavbarWithUser(user : User){
        
        messages.removeAll()
        messageDict.removeAll()
        tableView.reloadData()
        observeUserMessages()
        
        
        let titlteView = UIView()
        titlteView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titlteView.addSubview(containerView)
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        if let profileImageURl = user.profileImageUrl {
            profileImageView.loadImageUsignCacheWithUrlString(urlString: profileImageURl)
        }
        
        containerView.addSubview(profileImageView)
        
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel = UILabel()
        containerView.addSubview(nameLabel)
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titlteView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titlteView.centerYAnchor).isActive = true
        
        self.navigationItem.titleView = titlteView
    }
    
    @objc func handleLogOut(){
        do{
            try Auth.auth().signOut()
        } catch let logOutError {
            print(logOutError.localizedDescription)
        }
        let logInVC =  SignUpViewController()
        logInVC.chatsVC = self
        performSegue(withIdentifier: "fromChatToSigIn", sender: nil)
    }
    
    @objc func handleNewMessage(){
        let newMessageVC = ContactsList()
        newMessageVC.messagesVC = self
        let navController = UINavigationController(rootViewController: newMessageVC)
        present(navController, animated: true, completion: nil)
    }
    
    @objc func showChatControllerForUser(user : User){
        
        let chatVC = ChatViewController(collectionViewLayout: UICollectionViewFlowLayout())
        chatVC.user = user
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    //MARK: -TbaleView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let uid = Auth.auth().currentUser?.uid else{
            return
        }
        
       let message = self.messages[indexPath.row]
        
        if let chatPartnerId = message.partenerId(){
            Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue { (error, ref) in
                if error != nil{
                    self.showAlert(message: error!.localizedDescription)
                    return
                }
                
                self.messageDict.removeValue(forKey: chatPartnerId)
                self.reload()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let message = messages[indexPath.row]
        guard let partner = message.partenerId() else{
            return
        }
        
        let ref = Database.database().reference().child("users").child(partner)
        
        ref.observeSingleEvent(of: .value) { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String : String] else{
                return
            }
            
            let user = User()
            user.id = partner
            user.name = dictionary["name"]
            user.email = dictionary["email"]
            user.profileImageUrl = dictionary["profileImageUrl"]
            self.showChatControllerForUser(user: user)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let message = messages[indexPath.row]
        cell.message = message
        return cell
    }
}
