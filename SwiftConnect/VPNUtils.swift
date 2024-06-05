//
//  VPNUtils.swift
//  SwiftConnect
//
//  Created by Wenyu Zhao on 8/12/2021.
//

import Foundation
import SwiftUI
import Security



enum VPNState {
    case stopped, processing, launched
    
    var description : String {
      switch self {
      case .stopped: return "stopped"
      case .processing: return "launching"
      case .launched: return "launched"
      }
    }
}

class VPNController: ObservableObject {
    @Published public var state: VPNState = .stopped
    
    private var currentLogURL: URL?;
    private var vpnConnector: VPNConnector?;
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.vpnStatusDidChanged(notification:)), name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
    }
    
    @objc func vpnStatusDidChanged(notification: Notification) {
        let session : NETunnelProviderSession = notification.object as! NETunnelProviderSession
        let connected : Bool = session.status == NEVPNStatus.connected
        AppDelegate.shared.vpnConnectionDidChange(connected: connected)
        AppDelegate.shared.pinPopover = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            AppDelegate.shared.closePopover()
        }
        if(connected) {
            state = .launched
        } else {
            state = .stopped
        }
    }
    
    func start(hostAndPort: HostAndPort) {
        AppDelegate.shared.pinPopover = true
        start(host: hostAndPort.host, port: hostAndPort.port) { succ in
            AppDelegate.shared.pinPopover = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                AppDelegate.shared.closePopover()
            }
        }
    }
    
    private func start(host: String, port: String, _ onLaunch: @escaping (_ succ: Bool) -> Void) {
        state = .processing
        AppDelegate.shared.vpnConnectionDidChange(connected: false)
        AppDelegate.vpnConnector.connectHost(host, port: port)
    }
    
    func kill() {
        AppDelegate.vpnConnector.stopVPNTunnel()
        state = .stopped
    }
    
    func openLogFile() {
    }
}



class HostAndPort: ObservableObject {
    @Published public var host: String
    @Published public var port: String
    
    init() {
        let conf = AppDelegate.vpnConnector.vpnConfiguration()
        if conf == nil {
            host = ""
            port = "20240"
        } else {
            host = conf?["host"] as! String;
            port = conf?["port"] as! String;
        }
    }
}

