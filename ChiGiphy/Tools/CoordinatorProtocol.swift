//
//  CoordinatorProtocol.swift
//
//  Created by Hardijs on 18/12/2020.
//

import UIKit

protocol CoordinatorProtocol {
    var childCoordinators: [CoordinatorProtocol] { get set }
    var navigationController: UINavigationController { get set }
    func start()
}
