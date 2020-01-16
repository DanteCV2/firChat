//
//  SignUpViewController.swift
//  firApp
//
//  Created by Dante Cervantes Vega on 31/12/19.
//  Copyright © 2019 Dante Cervantes Vega. All rights reserved.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var topView: UIView!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var cPasswordTextField: UITextField!
    @IBOutlet var signUpButton: UIButton!
    @IBOutlet var marginTop: NSLayoutConstraint!
    
    var chatsVC : ChatsList?
    var activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setView()
    }
    
    @IBAction func signUpPressed(_ sender: UIButton) {
        
        guard nameTextField.text != "" else{
            showAlert(message: "Please provide an user name.")
            return
        }
        
        guard let email = emailTextField.text else {
            showAlert(message: "Please provide an email.")
            return
        }
        
        guard passwordTextField.text == cPasswordTextField.text else {
            showAlert(message: "Passwords do not match")
            return
        }
        
        authUser(email: email)
    }
    
    //MARK: -Firebase Methods
    
    private func authUser(email : String){
        
        showIndicator()
        Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
            if error !=  nil{
                self.showAlert(message: "\(error!.localizedDescription)")
                return
            }
            
            guard let uid = user?.user.uid else {
                return
            }
            
            let imageName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).jpg")
            
            if let uploadData = self.profileImageView.image!.jpegData(compressionQuality: 0.1){
                storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                    
                    if error != nil{
                        self.showAlert(message: "\(error!.localizedDescription)")
                        return
                    }
                    
                    storageRef.downloadURL { (url, error) in
                        
                        if error != nil{
                            self.showAlert(message: "\(error!.localizedDescription)")
                            return
                        }
                        
                        if let imageUrl = url?.absoluteString{
                            let values = ["name" : self.nameTextField.text!, "email" : email, "profileImageUrl" : imageUrl]
                            self.registerUserInDbWithUID(uid: uid, values: values)
                            self.performSegue(withIdentifier: "userRegister", sender: nil)
                        }
                    }
                }
            }
        }
        UIView.setAccessibilityRespondsToUserInteraction(false)
    }
    
    private func registerUserInDbWithUID(uid : String, values : [String : String]){
        
        let ref = Database.database().reference()
        let userReference = ref.child("users").child(uid)
        
        userReference.updateChildValues(values) { (error, ref) in
            
            if error != nil{
                self.showAlert(message: "\(error!.localizedDescription)")
                return
            }
            
            let user = User()
            user.id = uid
            user.name = values["name"]
            user.email = values["email"]
            user.profileImageUrl = values["profileImageUrl"]
            self.chatsVC?.setupNavbarWithUser(user: user)
        }
    }
    
    //MARK: - UIVIEW Configuration
    
    func setView(){
        topView.setGrandientBackground()
        bottomView.layer.cornerRadius = 20
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.layer.borderWidth = 4
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageViewTapped)))
        profileImageView.isUserInteractionEnabled = true
        signUpButton.layer.cornerRadius = 20
        signUpButton.clipsToBounds = true
        signUpButton.setGrandientBackground()
    }
    
    func showIndicator(){
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .medium
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        UIView.setAccessibilityRespondsToUserInteraction(true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

// MARK: -Image Picker Extension

extension SignUpViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func profileImageViewTapped(){
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImageFromPicker : UIImage?
        
        if let editedImage = info[.editedImage]{
            selectedImageFromPicker = editedImage as? UIImage
        }else if let originalImage = info[.originalImage]{
            selectedImageFromPicker = originalImage as? UIImage
        }
        
        if let selectedImage = selectedImageFromPicker{
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
