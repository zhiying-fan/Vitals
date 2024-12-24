//
//  AppDelegate.swift
//  Vitals
//
//  Created by zhiying-fan on 12/17/2024.
//  Copyright (c) 2024 zhiying-fan. All rights reserved.
//

import UIKit
import Vitals
import CryptoKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Task {
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            let appID = "didi"
            let outUserID = "1"
            let sign = generateSign(appID: appID, outUserID: outUserID, timestamp: timestamp, key: "9d31e4d550c94cf5a8699be7b3877866")
            let option = VitalsInitOption(serverURL: "http://api-sdk.utours.cn", outUserID: outUserID, appID: appID, timestamp: timestamp, sign: sign)
            
            try? await VitalsSDK.shared.initialize(vitalsInitOption: option)
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func generateSign(appID: String, outUserID: String, timestamp: Int, key: String) -> String {
        var params = [
            ("appId", appID),
            ("outUserId", outUserID),
            ("timestamp", "\(timestamp)")
        ]
        
        params.sort { $0.0 < $1.0 }
        
        let signStr = params.map { "\($0.0)=\($0.1)" }.joined(separator: "&") + "&key=\(key)"
        
        // 生成 MD5 签名
        let md5Sign = md5(string: signStr)
        return md5Sign
    }
    
    func md5(string: String) -> String {
        Insecure.MD5
            .hash(data: string.data(using: .utf8)!)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

