//
//  Extensions.swift
//  Luxamp
//
//  Created by Jaden Bernal on 2/3/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import Foundation


extension Array {
    public init(count: Int, elementCreator: @autoclosure () -> Element) {
        self = (0 ..< count).map { _ in elementCreator() }
    }
}
