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

import Foundation

private enum CoordinatorTransitionStyle {
    case forwards
    case last
    case backwardsSearch
}

open class CoordinatorReference<StateType: Equatable> {
    
    open fileprivate(set) var currentState: StateType
    fileprivate var _previousStates = [StateType]()
    
    open var previousState: StateType? {
        return _previousStates.last
    }
    
    open func previousStates() -> [StateType] {
        return _previousStates
    }
    
    fileprivate init(initialState: StateType) {
        currentState = initialState
    }
    
    open func canTransitionToState(_ newState: StateType) -> Bool {
        fatalError("implement")
    }
    
    open func transitionToState(_ newState: StateType) {
        fatalError("implement")
    }
    
    open func transitionBackToState(_ newState: StateType) {
        fatalError("implement")
    }
    
    open func canTransitionBack() -> Bool {
        fatalError("implement")
    }
    
    open func transitionBack() {
        fatalError("implement")
    }
    
    open func unload() {
        fatalError("implement")
    }
    
}

public protocol CoordinatorManager: class {
    
    associatedtype StateType: Equatable
    
    weak var coordinator: CoordinatorReference<StateType>! { get set }
    
    /// The initial state of the CoordinatorManager. The CoordinatorManager should not require any effort to reach this state.
    var initialState: StateType { get }
    
    /**
     Determine if the given state transition is valid.
     
     - parameter fromState: The state to transition from.
     - parameter toState:   The state to transition to.
     
     - returns: true if the state transition is valid; otherwise, false.
     */
    func canTransition(fromState: StateType, toState: StateType) -> Bool
    
    /**
     Perform any logic necessary to transition between the given states.
     
     - parameter fromState: The current to transition from.
     - parameter toState:   The new state to transition to.
     */
    func transition(fromState: StateType, toState: StateType, forwards: Bool)
    
}

public protocol CoordinatorImplicitTransitionReversalDelegate: class {
    
    /// If all state transitions are of the form (A <-> B), and never (A -> B) return true in this method.
    var allowImplicitTransitionReversals: Bool { get }
    
}

public protocol CoordinatorManagerBackwards: class {
    
    associatedtype StateType: Equatable
    
    func transition(fromState: StateType, toState: StateType, forwards: Bool)
    
}

final public class Coordinator<StateType: Equatable, CM: CoordinatorManager>: CoordinatorReference<CM.StateType> where CM.StateType == StateType {
    
    open var coordinatorManager: CM!
    
    /**
     Initialize a Coordinator with the given CoordinatorManager. After being initialized, the CoordinatorManager should not be interacted with directly.
     
     - parameter cm: The CoordinatorManager.
     
     - returns: An initialized Coordinator.
     */
    public init(coordinatorManager cm: CM) {
        coordinatorManager = cm
        super.init(initialState: cm.initialState)
        coordinatorManager.coordinator = self
    }
    
    /**
     Determine if the Coordinator can transition from its current state to a new state.
     
     - parameter newState: The new state you'd like to transition to.
     
     - returns: true if the Coordinator can transition from its current state to the new state; otherwise, false.
     */
    public override func canTransitionToState(_ newState: StateType) -> Bool {
        if let previousState = _previousStates.last {
            if newState == previousState {
                if let cm = coordinatorManager as? CoordinatorImplicitTransitionReversalDelegate , cm.allowImplicitTransitionReversals {
                    return true
                }
            }
        }
        
        return coordinatorManager.canTransition(fromState: currentState, toState: newState)
    }
    
    /**
     Transition from the current state to the new state. A fatalError will occur if you attempt to transition to an invalid state.
     
     - parameter newState: The new state to transition to.
     */
    public override func transitionToState(_ newState: StateType) {
        transitionToState(newState, transitionStyle: .forwards)
    }
    
    public override func transitionBackToState(_ newState: StateType) {
        transitionToState(newState, transitionStyle: .backwardsSearch)
    }
    
    /**
     Determine if the Coordinator can transition from the current state to its previous state.
     
     - returns: true if a valid previous state exists and can be transition to; otherwise, false.
     */
    public override func canTransitionBack() -> Bool {
        if let previousState = _previousStates.last {
            return canTransitionToState(previousState)
        } else {
            return false
        }
    }
    
    /**
     Transition from the current state to the previous state. A fatalError will occur if you attempt to transition to an invalid state.
     */
    public override func transitionBack() {
        if let previousState = _previousStates.last {
            transitionToState(previousState, transitionStyle: .last)
        } else {
            fatalError("Illegal state transition, there is no previous state")
        }
    }
    
    /**
     Clear the state stack of previous states.
     */
    public func clearStateStack() {
        _previousStates.removeAll(keepingCapacity: false)
    }
    
    public override func unload() {
        coordinatorManager = nil
    }
    
    fileprivate func transitionToState(_ newState: StateType, transitionStyle: CoordinatorTransitionStyle) {
        if transitionStyle == .backwardsSearch {
            if !_previousStates.contains(newState) {
                fatalError("Illegal state transition: There is no previous state \(newState)")
            }
        }
        
        if currentState != newState {
            if canTransitionToState(newState) {
                let forwards: Bool
                
                switch transitionStyle {
                case .forwards:
                    forwards = true
                    _previousStates.append(currentState)
                case .last:
                    forwards = false
                    _previousStates.removeLast()
                case .backwardsSearch:
                    forwards = false
                    
                    for state in _previousStates.reversed() {
                        _previousStates.removeLast()
                        
                        if state == newState {
                            break
                        }
                    }
                }
                
                let cState = currentState
                currentState = newState
                coordinatorManager.transition(fromState: cState, toState: newState, forwards: forwards)
            } else {
                fatalError("Illegal state transition: \(currentState) -> \(newState)")
            }
        }
    }
}
