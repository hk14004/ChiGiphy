//
//  ReachabilityManager.swift
//  ChiGiphy
//
//  Created by Hardijs on 05/03/2021.
//

import Foundation
import RxSwift
import RxReachability
import Reachability

class ReachabilityManager: ReachabilityManagerProtocol {

    static var shared = ReachabilityManager()
    
    let reachability = Reachability()
    
    private init() {
        try? reachability?.startNotifier()
    }
}

protocol ReachabilityManagerProtocol {
    var reachability: Reachability? { get }
}
