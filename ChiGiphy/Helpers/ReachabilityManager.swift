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
    
    let reachability: Reachability = Reachability()!
    
    private init() {
        do  {
            try reachability.startNotifier()
        } catch {
            print(error)
        }
    }
}

protocol ReachabilityManagerProtocol {
    var reachability: Reachability { get }
}

enum ReachabilityError: LocalizedError {
    case disconnected
    
    public var errorDescription: String? {
        switch self {
        case .disconnected:
            return NSLocalizedString(
                "The internet connection appears to be offline",
                comment: "Device is offline"
            )
        }
    }
}
