//
//  Toggler.swift
//  ToneBarrier
//
//  Created by Xcode Developer on 6/3/24.
//

import Foundation

struct Toggler {
    private var toggle: UInt = 1
    
    init() {
        var toggle = self.toggle
        togglerInstance = {
            toggle = (toggle ^ 1)
            return toggle
        }
    }
    
    let togglerInstance: () -> UInt
    
    func useToggler() -> UInt {
        return togglerInstance()
    }
    
    func miscellaneousFunction() -> UInt {
        return useToggler()
    }
}
