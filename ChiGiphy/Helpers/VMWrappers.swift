//
//  VMWrappers.swift
//  ChiGiphy
//
//  Created by Hardijs on 01/03/2021.
//

import Foundation
import RxSwift
import RxCocoa

@propertyWrapper
struct VMInput<T> {

    private let subject = PublishSubject<T>()

    var wrappedValue: AnyObserver<T> {
        return subject.asObserver()
    }

    var projectedValue: PublishSubject<T> {
        return subject
    }
}

@propertyWrapper
struct VMProperty<T> {

    private let relay: BehaviorRelay<T>

    init(_ defaultValue: T) {
        self.relay = .init(value: defaultValue)
    }

    var wrappedValue: Driver<T> {
        return relay.asDriver()
    }

    var projectedValue: BehaviorRelay<T> {
        return relay
    }
}

@propertyWrapper
struct VMOutput<T> {

    private let subject = PublishSubject<T>()

    var wrappedValue: Driver<T> {
        return subject.asDriver { (error) -> Driver<T> in
            fatalError(error.localizedDescription)
        }
    }

    var projectedValue: PublishSubject<T> {
        return subject
    }
}
