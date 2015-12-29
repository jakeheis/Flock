//
//  Flockfile.swift
//  Flock
//
//  Created by Jake Heiser on 12/28/15.
//  Copyright © 2015 jakeheis. All rights reserved.
//

//import Flock

struct Flockfile {
    init(flock: Flock) {
        flock.use(FlockCurassow)
    }
}

