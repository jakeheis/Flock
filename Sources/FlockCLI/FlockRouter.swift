//
//  FlockRouter.swift
//  FlockCLI
//
//  Created by Jake Heiser on 10/30/16.
//
//

import SwiftCLI

class FlockRouter: Router {
    
    func route(cli: CLI, arguments: ArgumentList) -> RouteResult {
        let path = CommandGroupPath(cli: cli)
        
        // Just ran `flock`
        guard let name = arguments.head else {
            return .failure(partialPath: path, notFound: nil)
        }
        
        // Ran something like `flock --init`
        if let command = cli.children.first(where: { $0.name == name.value }) as? Command {
            arguments.remove(node: name)
            return .success(path.appending(command))
        }
        
        // Ran something like `flock --notreal`
        if name.value.hasPrefix("-") {
            return .failure(partialPath: path, notFound: name.value)
        }
        
        // Ran something like `flock deploy`
        return .success(path.appending(ForwardCommand()))
    }
    
}
