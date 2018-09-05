//
//  UtilFunctions.swift
//  Go
//
//  Created by Victor Idongesit on 05/09/2018.
//  Copyright © 2018 Victor Idongesit. All rights reserved.
//

import Foundation

class Utilities {
    static func valueForAPIKey(keyname: String) -> String? {
        let filePath = Bundle.main.path(forResource: "Keys", ofType: "plist")
        if let path = filePath {
            let pList = NSDictionary(contentsOfFile: path)
            let value: String? = pList?.object(forKey: keyname) as? String
            return value
        } else {
            print("Create a .plist file to hold the API Keys")
            return nil
        }
    }

}
