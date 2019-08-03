//
//  Cache.swift
//  Astronomy
//
//  Created by Dongwoo Pae on 8/2/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation

class Cache<Key: Hashable, Value> {
    
    private var cachedDatas: [Key: Value] = [:]

    func cache(value: Value, for key: Key) {
        queue.async {
            self.cachedDatas[key] = value
        }
    }
    
    func value(for key: Key) -> Value? {
        return queue.sync {self.cachedDatas[key]}
    }
    
    private let queue = DispatchQueue(label: "cache serial queue")
}

