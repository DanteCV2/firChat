//
//  ContactsViewController.swift
//  firApp
//
//  Created by Dante Cervantes Vega on 01/01/20.
//  Copyright © 2020 Dante Cervantes Vega. All rights reserved.
//

import UIKit
import Firebase

class ContactsList: UITableViewController {
    
    let cellId = "cellId"
    var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        fetchUsers()
    }
    
    func fetchUsers(){
        
        Database.database().reference().child("users").observe(.childAdded) { (snapshot) in
            if let dictionary = snapshot.value as? [String : String]{
                let user = User()
                user.id = snapshot.key
                user.name = dictionary["name"]
                user.email = dictionary["email"]
                user.profileImageUrl = dictionary["profileImageUrl"]
                self.users.append(user)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let user = users[indexPath.row]
        
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        
        if let profileImageURL = user.profileImageUrl{
            cell.profileImageView.loadImageUsignCacheWithUrlString(urlString: profileImageURL)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    var messagesVC : ChatsList?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) {
            let user = self.users[indexPath.row]
            self.messagesVC?.showChatControllerForUser(user: user)
        }
    }
}
