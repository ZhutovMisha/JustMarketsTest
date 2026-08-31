//
//  XCTestCase+MemoryLeak.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 31.08.2026.
//

import XCTest

extension XCTestCase {
    
    /// Registers a teardown check to verify that an object is deallocated after the test.
    /// - Parameters:
    ///   - instance: The object to monitor for deallocation.
    ///   - file: The source file to report if the object remains allocated.
    ///   - line: The source line to report if the object remains allocated.
    func trackForMemoryLeaks(
        _ instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Instance should have been deallocated. Potential Memory Leak",
                file: file,
                line: line
            )
        }
    }
}
