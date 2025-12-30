//
//  PianoKeyboardViewModel.swift
//  PianoKeyboard
//
//  Created by Gary Newby on 20/03/2023.
//

import SwiftUI

public protocol PianoKeyboardDelegate: AnyObject {
    func pianoKeyUp(_ keyNumber: Int)
    func pianoKeyDown(_ keyNumber: Int)
}

public class PianoKeyboardViewModel: ObservableObject, PianoKeyViewModelDelegateProtocol {
    @Published public var keys: [PianoKeyViewModel] = []
    @Published public var noteOffset = 48
    @Published public var showLabels = true
    @Published public var latch = true {
        didSet { reset() }
    }
    
    @Published public var selectedKeys: [PianoKeyViewModel] = []
    
    public var keyRects: [CGRect] = []
    public weak var delegate: PianoKeyboardDelegate?
    public var numberOfKeys = 25 {
        didSet { configureKeys() }
    }
    public var naturalKeyCount: Int {
        keys.filter { $0.isNatural }.count
    }
    
    var touches: [CGPoint] = [] {
        didSet { updateKeys() }
    }
    
    public init() {
        configureKeys()
    }
    
    func naturalKeyWidth(_ width: CGFloat, space: CGFloat) -> CGFloat {
        (width - (space * CGFloat(naturalKeyCount - 1))) / CGFloat(naturalKeyCount)
    }
    
    public func clearAllKeys(){
        for i in 0..<numberOfKeys {
            keys[i].touchDown = false
            keys[i].latched = false
            delegate?.pianoKeyUp(keys[i].noteNumber)
            selectedKeys = []
        }
    }
    
    private func configureKeys() {
        keys = Array(repeating: PianoKeyViewModel(keyIndex: 0, delegate: self), count: numberOfKeys)
        keyRects = Array(repeating: .zero, count: numberOfKeys)
        
        for i in 0..<numberOfKeys {
            keys[i] = PianoKeyViewModel(keyIndex: i, delegate: self)
        }
    }
    
    private func updateKeys() {
        var keyDownAt = Array(repeating: false, count: numberOfKeys)
        
        // Only mark which keys are being touched - don't modify selectedKeys here
        for touch in touches {
            if let index = getKeyContaining(touch) {
                keyDownAt[index] = true
            }
        }
        
        for index in 0..<numberOfKeys {
            let noteNumber = keys[index].noteNumber
            
            // Only process when key state CHANGES
            if keys[index].touchDown != keyDownAt[index] {
                if latch {
                    let keyLatched = keys[index].latched
                    
                    if keyDownAt[index] && keyLatched {
                        // Key is being pressed and was already latched - unlatch it
                        delegate?.pianoKeyUp(noteNumber)
                        keys[index].latched = false
                        keys[index].touchDown = false
                        // Remove from selectedKeys when unlatching
                        selectedKeys.removeAll { $0.noteNumber == noteNumber }
                    }
                    if keyDownAt[index] && !keyLatched {
                        // Key is being pressed and was not latched - latch it
                        delegate?.pianoKeyDown(noteNumber)
                        keys[index].latched = true
                        keys[index].touchDown = true
                        // Add to selectedKeys when latching (avoid duplicates)
                        if !selectedKeys.contains(where: { $0.noteNumber == noteNumber }) {
                            selectedKeys.append(keys[index])
                        }
                    }
                    
                } else {
                    // Non-latch mode (play mode)
                    if keyDownAt[index] {
                        delegate?.pianoKeyDown(noteNumber)
                    } else {
                        delegate?.pianoKeyUp(noteNumber)
                    }
                    keys[index].touchDown = keyDownAt[index]
                }
            }
        }
    }
    
    private func getKeyContaining(_ point: CGPoint) -> Int? {
        var keyNum: Int?
        for index in 0..<numberOfKeys {
            if keyRects[index].contains(point) {
                keyNum = index
                if !keys[index].isNatural {
                    break
                }
            }
        }
        return keyNum
    }
    
    private func reset() {
        for i in 0..<numberOfKeys {
            keys[i].touchDown = false
            keys[i].latched = false
            delegate?.pianoKeyUp(keys[i].noteNumber)
            selectedKeys = []
        }
    }
}
