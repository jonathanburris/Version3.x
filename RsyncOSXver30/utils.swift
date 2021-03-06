//
//  utils.swift
//  Rsync
//
//  Created by Thomas Evensen on 09/02/16.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation

var GlobalMainQueue: DispatchQueue {
    return DispatchQueue.main
}

var GlobalBackgroundQueue: DispatchQueue {
    return DispatchQueue.global(qos: .background)
}

var GlobalUserInitiatedQueue: DispatchQueue {
    return DispatchQueue.global(qos: .userInitiated)
}

var GlobalUtilityQueue: DispatchQueue {
    return DispatchQueue.global(qos: .utility)
}

var GlobalUserInteractiveQueue: DispatchQueue {
    return DispatchQueue.global(qos: .userInteractive)
}

var GlobalDefaultQueue: DispatchQueue {
    return DispatchQueue.global(qos: .default)
}

// Used in mainTab to present info about process
enum displayProcessInfo {
    case Estimating
    case Executing
    case Set_max_Number
    case Logging_run
    case Count_files
    case Change_profile
    case Profiles_enabled
    case Abort
    case Blank
}

// Protocol for doing a refresh in main view after testing for connectivity
protocol Connections : class {
    func displayConnections()
}

// Static shared class Utils

final class Utils {
    
    private var indexBoolremoteserverOff:[Bool]?
    weak var delegate_testconnections:Connections?
    weak var delegate_profilemenu:AddProfiles?
    
    // Creates a singelton of this class
    class var  sharedInstance: Utils {
        struct Singleton {
            static let instance = Utils()
        }
        return Singleton.instance
    }
    
    // Display the correct command to execute
    // Used for displaying the commands only
    func setRsyncCommandDisplay(index:Int, dryRun:Bool) -> String {
        var str:String?
        let config = SharingManagerConfiguration.sharedInstance.getargumentAllConfigurations()[index] as? argumentsOneConfig
        if (dryRun) {
                str = SharingManagerConfiguration.sharedInstance.setRsyncCommand() + " "
                if let count = config?.argdryRunDisplay?.count {
                    for i in 0 ..< count {
                        str = str! + (config?.argdryRunDisplay![i])!
                    }
                }
        } else {
            str = SharingManagerConfiguration.sharedInstance.setRsyncCommand() + " "
                if let count = config?.argDisplay?.count {
                    for i in 0 ..< count {
                        str = str! + (config?.argDisplay![i])!
                    }
                }
            }
        return str!
    }
    
    // Test for TCP connection
    func testTCPconnection (_ addr:String, port:Int, timeout:Int) -> (Bool, String) {
        var connectionOK:Bool = false
        var str:String = ""
        let client:TCPClient = TCPClient(addr: addr, port: port)
        let (success, errmsg) = client.connect(timeout: timeout)
        connectionOK = success
        if connectionOK {
            str = "connection OK"
        } else {
            str = errmsg
        }
        return (connectionOK, str)
    }

    // Setting date format
    func setDateformat() -> DateFormatter {
        let dateformatter = DateFormatter()
        // We are forcing en_US format of date strings
        dateformatter.locale = Locale(identifier: "en_US")
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "dd MMM yyyy HH:mm"
        return dateformatter
    }

    // Getting the structure for test connection
    func gettestAllremoteserverConnections() -> [Bool]? {
        return self.indexBoolremoteserverOff
    }
    
    // Testing all remote servers.
    // Adding connection true or false in array[bool]
    // Do the check in background que, reload table in global main queue
    func testAllremoteserverConnections () {
        self.indexBoolremoteserverOff = nil
        self.indexBoolremoteserverOff = Array<Bool>()
        
        guard (SharingManagerConfiguration.sharedInstance.ConfigurationsDataSourcecount() > 0) else {
            if let pvc = SharingManagerConfiguration.sharedInstance.ViewObjectMain as? ViewControllertabMain {
                self.delegate_profilemenu = pvc
                // Tell main view profile menu might presented
                self.delegate_profilemenu?.enableProfileMenu()
            }
            return
        }
        
        GlobalDefaultQueue.async(execute: { () -> Void in
            var port:Int = 22
            for i in 0 ..< SharingManagerConfiguration.sharedInstance.ConfigurationsDataSourcecount() {
                let config = SharingManagerConfiguration.sharedInstance.getargumentAllConfigurations()[i] as? argumentsOneConfig
                if ((config?.config.offsiteServer)! != "") {
                    if let sshport:Int = config?.config.sshport {
                        port = sshport
                    }
                    let (success, _) = Utils.sharedInstance.testTCPconnection((config?.config.offsiteServer)!, port: port, timeout: 1)
                    if (success) {
                        self.indexBoolremoteserverOff!.append(false)
                    } else {
                        // self.remoteserverOff = true
                        self.indexBoolremoteserverOff!.append(true)
                    }
                } else {
                    self.indexBoolremoteserverOff!.append(false)
                }
                // Reload table when all remote servers are checked
                if i == (SharingManagerConfiguration.sharedInstance.ConfigurationsDataSourcecount() - 1) {
                    // Send message to do a refresh
                    if let pvc = SharingManagerConfiguration.sharedInstance.ViewObjectMain as? ViewControllertabMain {
                        self.delegate_testconnections = pvc
                        self.delegate_profilemenu = pvc
                        // Update table in main view
                        self.delegate_testconnections?.displayConnections()
                        // Tell main view profile menu might presented
                        self.delegate_profilemenu?.enableProfileMenu()
                    }
                }
            }
        })
    }
    
 }

