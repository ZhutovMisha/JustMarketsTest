//
//  XCTestCase+MemoryLeak.swift
//  JustMarketsTests
//
//  Created by Zhutov Mykhailo on 31.08.2026.
//

import XCTest

extension XCTestCase {
    
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
