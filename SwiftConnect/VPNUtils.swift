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
    
    func start(credentials: Credentials, save: Bool) {
        if save {
            credentials.save()
        }
        AppDelegate.shared.pinPopover = true
        start(portal: credentials.portal, port: credentials.port, password: credentials.port) { succ in
            AppDelegate.shared.pinPopover = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                AppDelegate.shared.closePopover()
            }
        }
    }
    
    private func start(portal: String, port: String, password: String, _ onLaunch: @escaping (_ succ: Bool) -> Void) {
        state = .processing
        AppDelegate.shared.vpnConnectionDidChange(connected: false)
        AppDelegate.vpnConnector.connectHost(portal, port: port)
    }
    
    func kill() {
        AppDelegate.vpnConnector.stopVPNTunnel()
        state = .stopped
    }
    
    func openLogFile() {
    }
}



class Credentials: ObservableObject {
    @Published public var portal: String
    @Published public var port: String
    
    init() {
        if let data = ContentView.inPreview ? nil : KeychainService.shared.load() {
            port = data.port
            portal = data.portal
        } else {
            portal = ""
            port = "20240"
        }
    }
    
    func save() {
        let _ = KeychainService.shared.insertOrUpdate(credentials: CredentialsData(portal: portal, port: port))
    }
}

struct CredentialsData {
    let portal: String
    let port: String
}

class KeychainService: NSObject {
    public static let shared = KeychainService();
    
    private static let server = "swift-connect.wenyu.me"
    
    func insertOrUpdate(credentials: CredentialsData) -> Bool {
        let username = credentials.port
        let password = "".data(using: String.Encoding.utf8)!
        let portal = credentials.portal
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: Self.server,
        ]
        let attributes: [String: Any] = [
            kSecAttrAccount as String: username,
            kSecValueData as String: password,
            kSecAttrDescription as String: portal,
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let query: [String: Any] = [
                kSecClass as String: kSecClassInternetPassword,
                kSecAttrAccount as String: username,
                kSecAttrServer as String: Self.server,
                kSecValueData as String: password,
                kSecAttrDescription as String: portal,
            ]
            let status = SecItemAdd(query as CFDictionary, nil)
            return status == errSecSuccess
        } else {
            return status == errSecSuccess
        }
    }
    
    func load() -> CredentialsData? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: Self.server,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else { return nil }
        
        guard let existingItem = item as? [String : Any],
            let username = existingItem[kSecAttrAccount as String] as? String,
            let portal = existingItem[kSecAttrDescription as String] as? String
        else {
            return nil
        }
        
        return CredentialsData(portal: portal, port: username)
    }
}
