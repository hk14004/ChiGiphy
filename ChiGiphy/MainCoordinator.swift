//
//  MainCoordinator.swift
//  ChiGiphy
//
//  Created by Hardijs on 11/01/2021.
//

import UIKit

// We don't need anything fancy here as we only have 1 screen
class MainCoordinator {
    
    func start(with window: UIWindow) {
        // Create VM
        let vm = GiphySearchVM()
        // Create VC
        let vc = GiphySearchVC(viewModel: vm)
        // Create nav VC
        let navVc = UINavigationController(rootViewController: vc)
        // Start
        window.rootViewController = navVc
        window.makeKeyAndVisible()
    }
}
