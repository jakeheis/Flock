//
//  HelpMessageGenerator.swift
//  FlockCLI
//
//  Created by Jake Heiser on 3/30/18.
//

import SwiftCLI

class HelpMessageGenerator: SwiftCLI.HelpMessageGenerator {
    
    func writeCommandList(for path: CommandGroupPath, to out: WritableStream) {
        DefaultHelpMessageGenerator().writeCommandList(for: path, to: out)
        if let tasks = try? Beak.generateTaskList() {
            out <<< "Tasks:"
            out <<< tasks
            out <<< ""
        }
    }
    
}
