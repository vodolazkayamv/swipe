//
//  ViewController.swift
//  swipe
//
//  Created by Masha Vodolazkaya on 29/04/2020.
//  Copyright © 2020 OpenTek. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        view.backgroundColor = UIColor(white: 249 / 255, alpha: 1)
        
        let joinButton = UIButton()
        joinButton.backgroundColor = .black
        joinButton.setTitle("Join Meeting", for: .normal)
        joinButton.addTarget(self, action: #selector(joinMeeting), for: .touchUpInside)
        joinButton.layer.cornerRadius = 5
        joinButton.frame = CGRect(x: view.center.x - 75, y: view.center.y - 25 + 60, width: 150, height: 50)
        view.addSubview(joinButton)
        
        let loginButton = UIButton()
        loginButton.backgroundColor = .black
        loginButton.setTitle("Login to ZOOM", for: .normal)
        loginButton.addTarget(self, action: #selector(loginToZOOM), for: .touchUpInside)
        loginButton.layer.cornerRadius = 5
        loginButton.frame = CGRect(x: view.center.x - 75, y: view.center.y - 25 - 60, width: 150, height: 50)
        view.addSubview(loginButton)
        
        let scheduleButton = UIButton()
        scheduleButton.backgroundColor = .black
        scheduleButton.setTitle("Schedule Meeting", for: .normal)
        scheduleButton.addTarget(self, action: #selector(scheduleMeeting), for: .touchUpInside)
        scheduleButton.layer.cornerRadius = 5
        scheduleButton.frame = CGRect(x: view.center.x - 75, y: view.center.y - 25 + 120, width: 150, height: 50)
        view.addSubview(scheduleButton)
        
    }
    
    
    @objc func loginToZOOM() {
        ZoomService.sharedInstance.login(email: "zapdosrye@gmail.com", password: "London.Test1")
    }
    
    @objc func scheduleMeeting() {
        let meeting = ZoomMeeting.init(number: 0, password: "123", topic: "Testing meeting scheduling", startTime: Date.init(), timeZone: TimeZone.current, durationInMinutes: 60)
        ZoomService.sharedInstance.scheduleMeeting(topic: "Testing meeting scheduling", startTime: Date.init(), durationInMinutes: TimeInterval.init(60))
        
        
    }
    
    @objc func joinMeeting() {
        
        //Step : 1
        let alert = UIAlertController(title: "Great Title", message: "Please input something", preferredStyle: UIAlertController.Style.alert )
        //Step : 2
        let save = UIAlertAction(title: "Save", style: .default) { (alertAction) in
            let textField = alert.textFields![0] as UITextField
            let textField2 = alert.textFields![1] as UITextField
            if textField.text != "" {
                //Read TextFields text data
                print(textField.text!)
                print("TF 1 : \(textField.text!)")
            } else {
                print("TF 1 is Empty...")
            }
            
            if textField2.text != "" {
                print(textField2.text!)
                print("TF 2 : \(textField2.text!)")
            } else {
                print("TF 2 is Empty...")
            }
            
            guard let meetingNumberText = textField.text,
                let meetingNumber = Int64(meetingNumberText),
                let meetingPassword = textField2.text else {
                    return
                    
            }
            
                ZoomService.sharedInstance.joinMeeting(number: meetingNumber, password: meetingPassword)
            

        }

        //Step : 3
        //For first TF
        alert.addTextField { (textField) in
            textField.placeholder = "Meeting identificator"
            textField.textColor = .red
        }
        //For second TF
        alert.addTextField { (textField) in
            textField.placeholder = "Password"
            textField.textColor = .blue
        }

        //Step : 4
        
        //Cancel action
        let cancel = UIAlertAction(title: "Cancel", style: .default) { (alertAction) in
            // nothing to do
        }
        alert.addAction(cancel)
        //OR single line action
        //alert.addAction(UIAlertAction(title: "Cancel", style: .default) { (alertAction) in })

        alert.addAction(save)
        
        self.present(alert, animated:true, completion: nil)
        
    }
}
