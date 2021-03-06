/*
The MIT License (MIT)

Copyright (c) 2015 Cameron Pulsford

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import UIKit
import XCTest
import Coordinator

enum State: Equatable {
    case unloaded
    case first
    case last
}

final class TestTransitionManager: CoordinatorManager {

    typealias StateType = State

    weak var coordinator: CoordinatorReference<StateType>!

    var initialState: StateType {
        get {
            return .unloaded
        }
    }

    func canTransition(#fromState: StateType, _ toState: StateType) -> Bool {
        switch (fromState, toState) {
        case (_, .Unloaded):
            fallthrough
        case (.Unloaded, .First):
            fallthrough
        case (.First, .Last):
            return true
        default:
            return false
        }
    }

    func transition(#fromState: StateType, _ toState: StateType) {

    }

}

class CoordinatorTests: XCTestCase {

    func testTransitions() {
        let c = Coordinator(coordinatorManager: TestTransitionManager())
        XCTAssertFalse(c.canTransitionBack(), "Should not have been able to transition back")
        XCTAssertTrue(c.canTransitionToState(.first), "Should have been able to transition")
        c.transitionToState(.first)
        XCTAssertTrue(c.canTransitionBack(), "Should have been able to transition back")
        XCTAssertTrue(c.canTransitionToState(.last), "Should have been able to transition")
        c.transitionToState(.last)
        XCTAssertFalse(c.canTransitionBack(), "Should not have been able to transition back")
    }
    
    
}
