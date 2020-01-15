//
//  ViewController.swift
//  firApp
//
//  Created by Dante Cervantes Vega on 30/12/19.
//  Copyright © 2019 Dante Cervantes Vega. All rights reserved.
//

import UIKit
import Firebase

class SignInViewController: UIViewController {
    
    @IBOutlet var topView: UIView!
    @IBOutlet var bottomView: UIView!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var signInButton: UIButton!
    
    var handle : AuthStateDidChangeListenerHandle?
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                self.performSegue(withIdentifier: "fromLogInToChat", sender: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    @IBAction func signInPressed(_ sender: UIButton) {
        sigIn()
    }
    
    //MARK: -Firebase Methods
    
    func sigIn(){
        
        guard let email = emailTextField.text else{
            return
        }
        
        guard let password = passwordTextField.text else{
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if error != nil {
                self.showAlert(message: error!.localizedDescription)
            }else{
                self.performSegue(withIdentifier: "fromLogInToChat", sender: nil)
            }
        }
    }
    
    //MARK: -View Configuration
    
    func setView(){
        topView.setGrandientBackground()
        bottomView.layer.cornerRadius = 20.0
        view.clipsToBounds = true
        view.setGrandientBackground()
        signInButton.layer.cornerRadius = 20
        signInButton.clipsToBounds = true
        signInButton.setGrandientBackground()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
