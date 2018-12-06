//
//  HelperFunctions.swift
//  Novagraph
//
//  Created by Sophie on 12/2/18.
//

import Foundation

public extension Dictionary {

    public func jsonStringify() -> String {
        if JSONSerialization.isValidJSONObject(self) {
            if let data = try? JSONSerialization.data(withJSONObject: self, options: .init(rawValue: 0)) {
                if let string = String(data: data, encoding: .utf8) {
                    return string.replacingOccurrences(of: "\"", with: "\\\"")
                }
            }
        }
        return ""
    }

}
