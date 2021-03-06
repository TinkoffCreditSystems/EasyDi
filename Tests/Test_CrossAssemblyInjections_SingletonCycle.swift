//
//  Test_CrossAssemblyInjections.swift
//  EasyDi
//
//  Created by Andrey Zarembo
//

import Foundation
import XCTest
import EasyDi

class Test_CrossAssemblyInjections_SingletonCycle: XCTestCase {
    fileprivate class TestObject {
        var childObject: TestChildObject? = nil
        var childObjects: [TestChildObject] = []
    }
    
    fileprivate class TestChildObject {
        weak var parentObject: TestObject? = nil
    }
    
    fileprivate class TestObjectAssembly: Assembly {
        lazy var testChildObjectAssembly: TestChildObjectAssembly = self.context.assembly()
        var testObject: TestObject {
            return define(scope: .lazySingleton, init: TestObject()) {
                
                $0.childObject = self.testChildObjectAssembly.testChildObject
                $0.childObjects = [
                    self.testChildObjectAssembly.testChildObject,
                    self.testChildObjectAssembly.testChildObjectPrototype,
                    self.testChildObjectAssembly.testChildObjectPrototype
                ]
                return $0
            }
        }
    }
    
    fileprivate class TestChildObjectAssembly: Assembly {
        var testObjectAssembly: TestObjectAssembly {
            return TestObjectAssembly.instance(from: self.context)
        }
        
        var testChildObject: TestChildObject {
            return define(init: TestChildObject()) {
                $0.parentObject = self.testObjectAssembly.testObject
                return $0
            }
        }
        
        var testChildObjectPrototype: TestChildObject {
            return define(scope: .prototype, init: TestChildObject()) {
                $0.parentObject = self.testObjectAssembly.testObject
                return $0
            }
        }
    }
    
    func testChildObjectIsCreates() {
        // Here and next contexts are used not to share any assembly instances between tests
        let context = DIContext()
        let testObject = TestObjectAssembly.instance(from: context).testObject
        XCTAssertNotNil(testObject.childObject)
    }
    
    func testParentObjectAssignedAndValud() {
        let context = DIContext()
        let testObject = TestObjectAssembly.instance(from: context).testObject
        XCTAssertNotNil(testObject.childObject?.parentObject)
        XCTAssert(testObject === testObject.childObject?.parentObject)
    }
    
    func testChildNotRecreated() {
        let context = DIContext()
        let testObject = TestObjectAssembly.instance(from: context).testObject
        XCTAssert(testObject.childObject === testObject.childObjects.first)
    }
    
    func testParentIsSameForAllChildren() {
        let context = DIContext()
        let testObject = TestObjectAssembly.instance(from: context).testObject
        for child in testObject.childObjects {
            XCTAssert(testObject === child.parentObject)
        }
    }
}
