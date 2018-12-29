//
//  AppDelegate.swift
//  ImageSyncSample
//
//  Created by dragonetail on 2018/12/29.
//  Copyright © 2018 dragonetail. All rights reserved.
//

import UIKit
import Photos

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        log.info("日志启动。")

        //CyaneaOctopus.setGlobalThemeUsingPrimaryColor(FlatMint, withSecondaryColor: FlatBlue,  andContentStyle: .contrast)
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        if authorizationStatus == .notDetermined {
            log.info("访问照片未授权。")
            PHPhotoLibrary.requestAuthorization({ status in
                if status == .authorized {
                    log.info("访问照片成功授权。")
                    self.startup(application)
                } else {
                    log.info("访问照片拒绝授权。")
                    self.alertAuthorizationStatus()
                }
            })
        } else if authorizationStatus == .authorized {
            self.startup(application)
        } else {
            log.info("访问照片授权状态非正常。")
            self.alertAuthorizationStatus()
        }

        return true
    }

    private func startup(_ application: UIApplication) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.window = UIWindow(frame: UIScreen.main.bounds)
            if let window = self.window {
                window.backgroundColor = UIColor.white

                let navigationController = UINavigationController(rootViewController: ViewController())
                navigationController.isNavigationBarHidden = false
                window.rootViewController = navigationController
                window.makeKeyAndVisible()
            }
        })
    }

    private func alertAuthorizationStatus() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.window = UIWindow(frame: UIScreen.main.bounds)
            if let window = self.window {
                let alertController = UIAlertController(title: "提示", message: "没有获取用户访问相册的授权。", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "知道了", style: .default, handler: {
                    action in
                    //noop
                }))

                window.rootViewController = ViewController()
                window.makeKeyAndVisible()
                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
        })
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

