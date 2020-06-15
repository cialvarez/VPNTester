//
//  ViewController.swift
//  VPNTest
//
//  Created by Christian Iñigo De Leon Alvarez on 6/15/20.
//  Copyright © 2020 Christian Iñigo De Leon Alvarez. All rights reserved.
//

import UIKit
import NetworkExtension
import WebKit

class ViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    var providerManager: NETunnelProviderManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadProviderManager {
            self.configureVPN(serverAddress: "85.204.116.217", username: "testvpnuser", password: "hellovpn123")
        }
     }

    func loadProviderManager(completion:@escaping () -> Void) {
       NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
           if error == nil {
               self.providerManager = managers?.first ?? NETunnelProviderManager()
               completion()
           }
       }
    }

    func configureVPN(serverAddress: String, username: String, password: String) {
      guard let configData = self.readFile(path: "Free-Server.ovpn") else { return }
      self.providerManager?.loadFromPreferences { error in
         if error == nil {
            let tunnelProtocol = NETunnelProviderProtocol()
            tunnelProtocol.username = username
            tunnelProtocol.serverAddress = serverAddress
            tunnelProtocol.providerBundleIdentifier = "com.cia.VPNTest.VPNTestNetworkExtension" // bundle id of the network extension target
            tunnelProtocol.providerConfiguration = ["ovpn": configData, "username": username, "password": password]
            tunnelProtocol.disconnectOnSleep = false
            
            self.providerManager.protocolConfiguration = tunnelProtocol
            self.providerManager.localizedDescription = "Test-OpenVPN" // the title of the VPN profile which will appear on Settings
            self.providerManager.isEnabled = true
            self.providerManager.saveToPreferences(completionHandler: { (error) in
                  if error == nil  {
                     self.providerManager.loadFromPreferences(completionHandler: { (error) in
                         do {
                           try self.providerManager.connection.startVPNTunnel() // starts the VPN tunnel.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                let request = URLRequest(url: URL(string: "https://www.whatismybrowser.com/detect/ip-address-location")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: .infinity)
                                self.webView.load(request)
                            }
//                            let request = URLRequest(url: URL(string: "https://www.whatismybrowser.com/detect/ip-address-location")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: .infinity)
//                            self.webView.load(request)
                         } catch let error {
                             print(error.localizedDescription)
                         }
                     })
                  }
            })
          }
       }
    }

    func readFile(path: String) -> Data? {
        guard let filePath = Bundle.main.url(forResource: "Free-Server", withExtension: "ovpn") else {
            return nil
        }

        do {
            return try Data(contentsOf: filePath, options: .uncached)
        }
        catch let error {
            print(error.localizedDescription)
        }
        return nil
    }
}
