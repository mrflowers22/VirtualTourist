//
//  CoreDataStack.swift
//  Virtual Tourists
//
//  Created by Michael Flowers on 3/3/20.
//  Copyright © 2020 Michael Flowers. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    //step 3: create a container to hold the stack
    let container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Flickr")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("unresolved error \(error), \(error.userInfo)")
            }
        })

        return container
    }()
    
    //step 5 create the context (MOC)
    var mainContext: NSManagedObjectContext {
        return container.viewContext
    }
}

