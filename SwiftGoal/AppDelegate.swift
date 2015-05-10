//
//  AppDelegate.swift
//  SwiftGoal
//
//  Created by Martin Richter on 10/05/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        window = UIWindow(frame: UIScreen.mainScreen().bounds)

        let matchesViewModel = MatchesViewModel(store: Store())
        let matchesViewController = MatchesViewController(viewModel: matchesViewModel)
        window?.rootViewController = UINavigationController(rootViewController: matchesViewController)
        window?.makeKeyAndVisible()

        return true
    }
}

