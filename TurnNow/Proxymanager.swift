//
//  Proxymanager.swift
//  TurnNow
//
//  Created by Mac on 10/27/20.
//

import Foundation
import SmartDeviceLink

class ProxyManager: NSObject, SDLManagerDelegate {
    //sdl variables
    private var appName:String = "Turn Now"
    private var appID:String = "12345"
    public var tcpip:String? = "m.sdl.tools"
    public var tcpport:Int?
    public var useTCPIPConnection:Bool = true
    public var useScreenMangerForButtons:Bool = false
    private var restartingProxy:Bool = false
    
    public var sdlManager: SDLManager!
    static let shared = ProxyManager()
    
    //app variables
    public var isSimStarted:Bool = false
    var leftCounter:String = ""
    var leftImage:UIImage = #imageLiteral(resourceName: "left_turn")
    var centerCounter:String = ""
    var centerImage:UIImage = #imageLiteral(resourceName: "straight")
    var rightCounter:String = ""
    var rightImage:UIImage = #imageLiteral(resourceName: "right_turn")
    var timer:Timer?
    
    
    override init() {
        super.init()
        self.setupManager()
        NotificationCenter.default.addObserver(self, selector: #selector(self.startStopPressed), name: .startStopPressed, object: nil)
    }
    
    /**
     *  Sets app details for SYNC registration
     */
    func setupManager() {
        if useTCPIPConnection && (tcpip == nil || tcpport == nil) {
            self.disconnect()
            return
        }
        let lifecycleConfig:SDLLifecycleConfiguration = useTCPIPConnection ? SDLLifecycleConfiguration(appName: appName, fullAppId: appID, ipAddress: tcpip!, port: UInt16(tcpport!)) : SDLLifecycleConfiguration(appName: appName, fullAppId: appID)
 
        let appIcon = SDLArtwork(image: #imageLiteral(resourceName: "icon"), name: "icon", persistent: true, as: .PNG)
        lifecycleConfig.appIcon = appIcon
        let lockConfig = SDLLockScreenConfiguration.enabled()
        let logConfig = SDLLogConfiguration.debug()
        logConfig.areAssertionsDisabled = true
        let configuration = SDLConfiguration(lifecycle: lifecycleConfig, lockScreen: lockConfig, logging: logConfig, fileManager: nil, encryption: nil)
        
        sdlManager = SDLManager(configuration: configuration, delegate: self)
    }
    
    /**
     *  Register app on SYNC
     */
    func connect() {
        guard self.sdlManager != nil else {return}
        self.sdlManager.start { (success, error) in
            if success {
                //App connected to sync
            }
        }
    }
    
    /**
     *  Unregister  app from SYNC
     */
    func disconnect() {
        guard self.sdlManager != nil else {return}
        self.sdlManager.stop()
    }
    /**
     *  Disconnect and Reconnect  app from SYNC
     */
    func cycleProxy() {
        if sdlManager == nil {
            setupManager()
            self.connect()
        }else{
            self.restartingProxy = true
            self.disconnect()
        }
    }
    
    //Mark - SDL MANAGER DELEGATE
    func managerDidDisconnect() {

        if restartingProxy {
            self.setupManager()
            self.connect()
            self.restartingProxy = false
        }
    }
    
    func hmiLevel(_ oldLevel: SDLHMILevel, didChangeToLevel newLevel: SDLHMILevel) {
        print("Went from HMI level \(oldLevel) to HMI level \(newLevel)")
        switch newLevel {
        case .full:        // The SDL app is in the foreground
          // Always try to show the initial state to guard against some possible weird states. Duplicates will be ignored by Core.
            self.showInitialData()
        case .limited:break    // An active NAV or MEDIA SDL app is in the background
        case .background:break    // The SDL app is not in the foreground
        case .none: break      // The SDL app is not yet running
        default: break
        }
      }
    
    //MARK - APP FUNCTIONS
    /// Set the template and create the UI
    func showInitialData() {
        guard sdlManager != nil else {return}
        guard sdlManager?.hmiLevel == .full else { return }
        self.changePrimaryImage(image: #imageLiteral(resourceName: "icon"))

        //add softbutton
        self.addSoftButton()
        //change layout
        self.updateConnection()
      }
    
    @objc func addSoftButton() {
        if useScreenMangerForButtons {
            addSoftButtonSM()
            return
        }
        guard self.sdlManager != nil else {return}
        //setup images
        let leftArtwork = SDLArtwork(image: leftImage, name: "leftImage", persistent: false, as: .JPG)
        leftArtwork.overwrite = true
        let centerArtwork = SDLArtwork(image: centerImage, name: "centerImage", persistent: false, as: .JPG)
        centerArtwork.overwrite = true
        let rightArtwork = SDLArtwork(image: rightImage, name: "rightImage", persistent: false, as: .JPG)
        rightArtwork.overwrite = true
        
        //upload images
        sdlManager.fileManager.upload(artworks: [leftArtwork,centerArtwork,rightArtwork]) { (artworkNames, error) in
            guard error == nil else {return}
            //setup softbuttons
            let softbutton1 = SDLSoftButton(type: .both, text: self.leftCounter, image: SDLImage(name: "leftImage", isTemplate: false), highlighted: false, buttonId: 0, systemAction: .none, handler: nil)
            let softbutton2 = SDLSoftButton(type: .both, text: self.centerCounter, image: SDLImage(name: "centerImage", isTemplate: false), highlighted: false, buttonId: 1, systemAction: .none, handler: nil)
            let softbutton3 = SDLSoftButton(type: .both, text: self.rightCounter, image: SDLImage(name: "rightImage", isTemplate: false), highlighted: false, buttonId: 2, systemAction: .none, handler: nil)
            //send softbuttons
            let show = SDLShow()
            show.softButtons = [softbutton1,softbutton2,softbutton3]
            self.sdlManager.send(request: show) { (request, response, error) in
                guard error != nil else { return }
                print("Textfields, graphics and soft buttons failed to update: \(error!.localizedDescription)")
            }
        }
    }
    @objc func addSoftButtonSM() {
        //add softbuttons using Screenmanager
        guard self.sdlManager != nil else {return}
        let softButtonState1 = SDLSoftButtonState(stateName: "AlertSoftButtonImageState", text: leftCounter, image: leftImage)
        let softButtonObject = SDLSoftButtonObject(name: "AlertSoftButton", states: [softButtonState1], initialStateName: softButtonState1.name) { (buttonPress, buttonEvent) in
                 guard buttonPress != nil else { return }
               }
        let softButtonState2 = SDLSoftButtonState(stateName: "AlertSoftButtonImageState1", text: centerCounter, image: centerImage)
        let softButtonObject2 = SDLSoftButtonObject(name: "AlertSoftButton1", states: [softButtonState2], initialStateName: softButtonState2.name) { (buttonPress, buttonEvent) in
                 guard buttonPress != nil else { return }
                 print("Soft button added")
               }
        let softButtonState3 = SDLSoftButtonState(stateName: "AlertSoftButtonImageState2", text: rightCounter, image: rightImage)
        let softButtonObject3 = SDLSoftButtonObject(name: "AlertSoftButton2", states: [softButtonState3], initialStateName: softButtonState3.name) { (buttonPress, buttonEvent) in
                 guard buttonPress != nil else { return }
               }
    
        self.sdlManager.screenManager.beginUpdates()
        self.sdlManager.screenManager.softButtonObjects = [softButtonObject, softButtonObject2, softButtonObject3]
        self.sdlManager.screenManager.endUpdates { (error) in
            guard error != nil else { return }
            print("Textfields, graphics and soft buttons failed to update: \(error!.localizedDescription)")
        }
    }
    func updateConnection(){
        guard self.sdlManager != nil else {return}
        let display = SDLSetDisplayLayout(predefinedLayout: .tilesWithGraphic)
        print("display for requst: \(display)")
        sdlManager?.send(request: display) { (request, response, error) in
            if response?.resultCode == .success {
              // The template has been set successfully
              print("The template has been set successfully")
            } else {
              print("error:\(String(describing: error))")
            }
        }
    }
    func changePrimaryImage(image:UIImage) {
        guard self.sdlManager != nil else {return}
        sdlManager.screenManager.beginUpdates()
        sdlManager.screenManager.primaryGraphic = SDLArtwork(image: image, name: "mainimage", persistent: false, as: .PNG)
        sdlManager.screenManager.endUpdates()
    }
    
    @objc func startStopPressed() {
        self.isSimStarted ? stopSimulation() : startSimulation()
    }
    
    func startSimulation() {
        self.isSimStarted = true
        NotificationCenter.default.post(Notification(name: .simStarted))
        //randomly pic one of the 3 buttons
        let randNum = Int.random(in: 0...2)
        //for that buttton start a countdown
        let countDownFrom = 5
        var runCount = 0
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            //update timer
            if runCount > countDownFrom {
                self.stopSimulation()
                return
            }
            
            //set text
            let text = "\(countDownFrom-runCount) seconds"
            switch randNum {
            case 0:
                self.leftCounter = text
            case 1:
                self.centerCounter = text
            case 2:
                self.rightCounter = text
            default:
                self.rightCounter = text
            }
            //update softbuttons
            self.addSoftButton()
            
            runCount += 1
        }
    }
    
    func stopSimulation() {
        self.isSimStarted = false
        NotificationCenter.default.post(Notification(name: .simStopped))
        timer?.invalidate()
        resetButtons()
    }
    
    func resetButtons() {
        //set all buttons to blank
        leftCounter = ""
        centerCounter = ""
        rightCounter = ""
        //send buttons
        self.addSoftButton()
    }
}

