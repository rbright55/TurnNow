//
//  ViewController.swift
//  TurnNow
//
//  Created by Mac on 10/13/20.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var centerImage: UIImageView!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var tcpSwitch: UISwitch!
    @IBOutlet weak var smSwitch: UISwitch!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var portLabel: UILabel!
    @IBOutlet weak var stackViewConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self,
                    selector: #selector(keyboardWillShow),
                    name: UIResponder.keyboardWillShowNotification,
                    object: nil)
        NotificationCenter.default.addObserver(self,
                    selector: #selector(keyboardWillHide),
                    name: UIResponder.keyboardWillHideNotification,
                    object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeButtonText), name: .simStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeButtonText), name: .simStopped, object: nil)
        setupTextFields()
        //setup inputs
        tcpSwitch.setOn(ProxyManager.shared.useTCPIPConnection, animated: true)
        ProxyManager.shared.useScreenMangerForButtons = smSwitch.isOn
        urlTextField.text = "\(ProxyManager.shared.tcpip ?? "")"
        if ProxyManager.shared.tcpport != nil {
            portTextField.text = "\(ProxyManager.shared.tcpport)"
        }
    }
    @IBAction func startStopButtonPressed(_ sender: Any) {
        NotificationCenter.default.post(Notification(name: .startStopPressed))
    }
    
    @objc func changeButtonText() {
        startStopButton.setTitle(ProxyManager.shared.isSimStarted ? "Stop" : "Start", for: .normal)
    }
    @IBAction func tcpSwitchPressed(_ sender: Any) {
        ProxyManager.shared.useTCPIPConnection = tcpSwitch.isOn
    }
    @IBAction func smSwitchPressed(_ sender: Any) {
        ProxyManager.shared.useScreenMangerForButtons = smSwitch.isOn
    }
    
    @IBAction func urlFieldDoneEditing(_ sender: Any) {
        //update info in Proxymanager
        ProxyManager.shared.tcpip = urlTextField.text
    }
    @IBAction func portFieldDoneEditing(_ sender: Any) {
        //update info in Proxymanager
        if !portTextField.text!.isEmpty {
            ProxyManager.shared.tcpport = Int(portTextField.text!)
            ProxyManager.shared.cycleProxy()
        }
    }
    @IBAction func resetButtonPressed(_ sender: Any) {
        ProxyManager.shared.cycleProxy()
    }
    
    func setupTextFields() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(hideKeyboard))
        toolbar.setItems([doneButton], animated: false)
        urlTextField.inputAccessoryView = toolbar
        portTextField.inputAccessoryView = toolbar
        portTextField.keyboardType = .numberPad
        
        urlTextField.delegate = self
        portTextField.delegate = self
    }
    
    @objc func hideKeyboard(){
        urlTextField.resignFirstResponder()
        portTextField.resignFirstResponder()
    }
    @objc func keyboardWillShow(sender: NSNotification) {
        let info = sender.userInfo!
        var keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        stackViewConstraint.constant = keyboardSize - bottomLayoutGuide.length

        let duration: TimeInterval = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        self.startStopButton.isHidden = true
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc func keyboardWillHide(sender: NSNotification) {
        let info = sender.userInfo!
        let duration: TimeInterval = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        stackViewConstraint.constant = 0
        self.startStopButton.isHidden = false
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
}

