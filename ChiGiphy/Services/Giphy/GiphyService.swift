//
//  GiphyService.swift
//  ChiGiphy
//
//  Created by Hardijs on 11/01/2021.
//

import Foundation
import RxSwift

protocol GiphyServiceProtocol {
    func search(text: String, offset: Int, limit: Int) -> Observable<[GiphyItem]>
    func downloadGif(url: URL) -> Observable<Data>
}

class GiphyService: GiphyServiceProtocol {
    
    // MARK: Vars
    
    private let apiKey = "X09nb1IgWr4u7dxoMJbZ8iQs3ClrlAM0"
    
    private let host = "http://api.giphy.com"
    
    // MARK: Methods
    
    func search(text: String, offset: Int, limit: Int) -> Observable<[GiphyItem]> {
        guard var urlComp = URLComponents(string: host) else { return .just([]) }
        urlComp.path = "/v1/gifs/search"
        urlComp.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let requestUrl = urlComp.url else { return .just([]) }
        return URLSession.shared.rx
            .decodable(request: URLRequest(url: requestUrl), type: GiphySearchResponse.self)
            .map {$0.data.elements}
    }
    
    func downloadGif(url: URL) -> Observable<Data> {
        return URLSession.shared.rx.data(request: URLRequest(url: url))
    }
}
