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

    var wrappedValue: Observable<T> {
        return relay.asObservable()
    }

    var projectedValue: BehaviorRelay<T> {
        return relay
    }
}

@propertyWrapper
struct VMOutput<T> {

    private let subject = PublishSubject<T>()

    var wrappedValue: Observable<T> {
        return subject.asObservable()
    }

    var projectedValue: PublishSubject<T> {
        return subject
    }
}
