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

    public init(id: String, image: Image) {
        self.id = id
        self.image = image
    }
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.id = try container.decode(String.self, forKey: .id)

      let images = try container.nestedContainer(keyedBy: ImageKeys.self, forKey: .images)
      self.image = try images.decode(Image.self, forKey: .preview_gif)
    }

    enum CodingKeys: String, CodingKey {
      case id
      case images
    }

    enum ImageKeys: String, CodingKey {
      case preview_gif = "preview_gif"
    }
  }

  extension GiphyItem {
    struct Image: Codable, Hashable {
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

extension GiphyItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
