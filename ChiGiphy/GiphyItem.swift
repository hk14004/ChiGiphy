//
//  GiphyItem.swift
//  ChiGiphy
//
//  Created by Hardijs on 11/01/2021.
//

import Foundation
import RxDataSources

struct GiphyItem: Decodable {
    let id: String
    let image: Image

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.id = try container.decode(String.self, forKey: .id)

      let images = try container.nestedContainer(keyedBy: ImageKeys.self, forKey: .images)
      self.image = try images.decode(Image.self, forKey: .downsized)
    }

    enum CodingKeys: String, CodingKey {
      case id
      case images
    }

    enum ImageKeys: String, CodingKey {
      case downsized = "downsized"
    }
  }

  extension GiphyItem {
    struct Image: Codable {
      let height: String
      let width: String
      let url: URL
    }
  }

extension GiphyItem: IdentifiableType {
    var identity: String {
        return id
    }
}

extension GiphyItem: Equatable {
    static func == (lhs: GiphyItem, rhs: GiphyItem) -> Bool {
        lhs.id == rhs.id
    }
}
