//
//  SearchError.swift
//  ChiGiphy
//
//  Created by Hardijs on 18/01/2021.
//

import Foundation

enum SearchError: Error {
    case underlyingError(Error)
    case notFound
    case unknown
}
