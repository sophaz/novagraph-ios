//
//  String+Novagraph.swift
//  Alamofire
//
//  Created by Sophie on 4/15/19.
//

import Foundation

extension String {
    func convertFromOpenIdToData() -> [String: Any]? {
        let splits = self.split(separator: ".")
        if splits.count > 1 {
            var string = String(splits[1])
            for _ in 0..<string.count % 4 {
                string += "="
            }
            if let data = Data(base64Encoded: string) {
                do {
                    let jsonData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                    return jsonData ?? nil
                }
            }
        }
        return nil
    }
}
