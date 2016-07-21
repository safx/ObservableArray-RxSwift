//
//  ObservableArrayTests.swift
//  ObservableArrayTests
//
//  Created by Safx Developer on 2015/12/30.
//  Copyright © 2016 Safx Developers. All rights reserved.
//

import XCTest
import RxSwift
@testable import ObservableArray

class ObservableArrayTests: XCTestCase {

    let disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInit() {
        XCTAssertEqual([], ObservableArray<Int>().elements)
    }

    func testInitSeqence() {
        XCTAssertEqual([], ObservableArray([Int]().generate()).elements)
        XCTAssertEqual([5,9,38], ObservableArray([5,9,38].generate()).elements)
    }

    func testInitCountRepeatedValue() {
        XCTAssertEqual([], ObservableArray(count: 0, repeatedValue: 9).elements)
        XCTAssertEqual([7,7,7], ObservableArray(count: 3, repeatedValue: 7).elements)
    }

    func testInitArrayLiteral() {
        let a: ObservableArray<Int> = []
        XCTAssertEqual([], a.elements)

        let b: ObservableArray = [4,8,13]
        XCTAssertEqual([4,8,13], b.elements)
    }

    func testStartIndex() {
        let a: ObservableArray<Int> = []
        XCTAssertEqual(0, a.startIndex)

        let b: ObservableArray = [4,8,13,22]
        XCTAssertEqual(0, b.startIndex)

        let c = ObservableArray(count: 999, repeatedValue: 4)
        XCTAssertEqual(0, c.startIndex)
    }

    func testEndIndex() {
        let a: ObservableArray<Int> = []
        XCTAssertEqual(0, a.endIndex)

        let b: ObservableArray = [4,8,13,22]
        XCTAssertEqual(4, b.endIndex)

        let c = ObservableArray(count: 999, repeatedValue: 4)
        XCTAssertEqual(999, c.endIndex)
    }

    func testCapacity() {
        var a: ObservableArray<Int> = []

        a.elements.reserveCapacity(3)
        XCTAssertLessThanOrEqual(3, a.capacity)

        a.elements.reserveCapacity(197)
        XCTAssertLessThanOrEqual(197, a.capacity)

        a.elements.reserveCapacity(5097)
        XCTAssertLessThanOrEqual(5097, a.capacity)
    }

    func testReserveCapacity() {
        var a: ObservableArray<Int> = []

        a.reserveCapacity(3)
        XCTAssertLessThanOrEqual(3, a.elements.capacity)

        a.reserveCapacity(197)
        XCTAssertLessThanOrEqual(197, a.elements.capacity)

        a.reserveCapacity(5097)
        XCTAssertLessThanOrEqual(5097, a.elements.capacity)
    }


    func testAppend() {
        var a: ObservableArray<String> = []

        a.append("foo")
        XCTAssertEqual(["foo"], a.elements)

        a.append("bar")
        XCTAssertEqual(["foo", "bar"], a.elements)
    }

    func testAppendRxElements() {
        var a: ObservableArray<String> = ["foo", "bar"]
        var observed = [[String]]()

        let exp = expectationWithDescription("event emitted")
        a.rx_elements().subscribeNext { (elements) -> Void in
            observed.append(elements)
            if observed.count == 2 {
                exp.fulfill()
            }
        }
        .addDisposableTo(disposeBag)

        a.append("buzz")

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        XCTAssertEqual(2, observed.count)
        XCTAssertEqual(["foo", "bar"], observed[0])
        XCTAssertEqual(["foo", "bar", "buzz"], observed[1])
    }

    func testAppendRxEvent() {
        var a: ObservableArray<String> = ["foo", "bar"]

        let exp = expectationWithDescription("event emitted")
        a.rx_events().subscribeNext { (event) -> Void in
            XCTAssertEqual([2], event.insertedIndices)
            XCTAssertTrue(event.deletedIndices.isEmpty)
            XCTAssertTrue(event.updatedIndices.isEmpty)
            exp.fulfill()
        }
        .addDisposableTo(disposeBag)

        a.append("buzz")

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAppendContentsOfSeqeunce() {
        var a: ObservableArray<String> = []

        a.appendContentsOf(["foo", "bar"].generate())
        XCTAssertEqual(["foo", "bar"], a.elements)

        a.appendContentsOf([].generate())
        XCTAssertEqual(["foo", "bar"], a.elements)

        a.appendContentsOf(["bazz", "tea", "coffee"].generate())
        XCTAssertEqual(["foo", "bar", "bazz", "tea", "coffee"], a.elements)
    }

    func testAppendContentsOfSeqeunceRxElements() {
        var a: ObservableArray<String> = ["foo", "bar"]
        var observed = [[String]]()

        let exp = expectationWithDescription("event emitted")
        a.rx_elements().subscribeNext { (elements) -> Void in
            observed.append(elements)
            if observed.count == 2 {
                exp.fulfill()
            }
        }
        .addDisposableTo(disposeBag)

        a.appendContentsOf(["bazz", "sugar"].generate())

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        XCTAssertEqual(2, observed.count)
        XCTAssertEqual(["foo", "bar"], observed[0])
        XCTAssertEqual(["foo", "bar", "bazz", "sugar"], observed[1])
    }

    func testAppendContentsOfSeqeunceRxEvent() {
        var a: ObservableArray<String> = ["foo", "bar"]

        let exp = expectationWithDescription("event emitted")
        a.rx_events().subscribeNext { (event) -> Void in
            XCTAssertEqual([2, 3, 4], event.insertedIndices)
            XCTAssertTrue(event.deletedIndices.isEmpty)
            XCTAssertTrue(event.updatedIndices.isEmpty)
            exp.fulfill()
        }
        .addDisposableTo(disposeBag)

        a.appendContentsOf(["buzz", "sugar", "tea"].generate())

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAppendContentsOfCollection() {
        var a: ObservableArray<String> = []

        a.appendContentsOf(["foo", "bar"])
        XCTAssertEqual(["foo", "bar"], a.elements)

        a.appendContentsOf([])
        XCTAssertEqual(["foo", "bar"], a.elements)

        a.appendContentsOf(["bazz", "tea", "coffee"])
        XCTAssertEqual(["foo", "bar", "bazz", "tea", "coffee"], a.elements)
    }

    func testAppendContentsOfCollectionRxElements() {
        var a: ObservableArray<String> = ["foo", "bar"]
        var observed = [[String]]()

        let exp = expectationWithDescription("event emitted")
        a.rx_elements().subscribeNext { (elements) -> Void in
            observed.append(elements)
            if observed.count == 2 {
                exp.fulfill()
            }
        }
        .addDisposableTo(disposeBag)

        a.appendContentsOf(["bazz", "sugar"])

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        XCTAssertEqual(2, observed.count)
        XCTAssertEqual(["foo", "bar"], observed[0])
        XCTAssertEqual(["foo", "bar", "bazz", "sugar"], observed[1])
    }

    func testAppendContentsOfCollectionRxEvent() {
        var a: ObservableArray<String> = ["foo", "bar"]

        let exp = expectationWithDescription("event emitted")
        a.rx_events().subscribeNext { (event) -> Void in
            XCTAssertEqual([2, 3, 4], event.insertedIndices)
            XCTAssertTrue(event.deletedIndices.isEmpty)
            XCTAssertTrue(event.updatedIndices.isEmpty)
            exp.fulfill()
        }
        .addDisposableTo(disposeBag)

        a.appendContentsOf(["buzz", "sugar", "tea"])

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }


    func testRemoveLast() {
        var a: ObservableArray<String> = ["foo", "bar"]

        XCTAssertEqual("bar", a.removeLast())
        XCTAssertEqual(["foo"], a.elements)

        XCTAssertEqual("foo", a.removeLast())
        XCTAssertEqual([], a.elements)
    }

    func testRemoveLastRxElements() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz", "tea"]
        var observed = [[String]]()

        let exp = expectationWithDescription("event emitted")
        a.rx_elements().subscribeNext { (elements) -> Void in
            observed.append(elements)
            if observed.count == 2 {
                exp.fulfill()
            }
        }
        .addDisposableTo(disposeBag)

        a.removeLast()

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }
        XCTAssertEqual(2, observed.count)
        XCTAssertEqual(["foo", "bar", "buzz", "tea"], observed[0])
        XCTAssertEqual(["foo", "bar", "buzz"], observed[1])
    }

    func testRemoveLastRxEvent() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz", "tea"]

        let exp = expectationWithDescription("event emitted")
        a.rx_events().subscribeNext { (event) -> Void in
            XCTAssertEqual([3], event.deletedIndices)
            XCTAssertTrue(event.insertedIndices.isEmpty)
            XCTAssertTrue(event.updatedIndices.isEmpty)
            exp.fulfill()
        }
        .addDisposableTo(disposeBag)

        a.removeLast()

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }


    func testInsert() {
        var a: ObservableArray<String> = ["foo", "bar"]

        a.insert("buzz", atIndex: 1)
        XCTAssertEqual(["foo", "buzz", "bar"], a.elements)

        a.insert("coffee", atIndex: 0)
        XCTAssertEqual(["coffee", "foo", "buzz", "bar"], a.elements)
    }

    func testInsertRxElements() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz"]
        var observed = [[String]]()

        let exp = expectationWithDescription("event emitted")
        a.rx_elements().subscribeNext { (elements) -> Void in
            observed.append(elements)
            if observed.count == 2 {
                exp.fulfill()
            }
        }
        .addDisposableTo(disposeBag)

        a.insert("milk", atIndex: 3)

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        XCTAssertEqual(2, observed.count)
        XCTAssertEqual(["foo", "bar", "buzz"], observed[0])
        XCTAssertEqual(["foo", "bar", "buzz", "milk"], observed[1])
    }

    func testInsertRxEvent() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz"]

        let exp = expectationWithDescription("event emitted")
        a.rx_events().subscribeNext { (event) -> Void in
            XCTAssertEqual([2], event.insertedIndices)
            XCTAssertTrue(event.deletedIndices.isEmpty)
            XCTAssertTrue(event.updatedIndices.isEmpty)
            exp.fulfill()
        }
        .addDisposableTo(disposeBag)

        a.insert("milk", atIndex: 2)

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }


    func testRemoveAtIndex() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz", "tea", "coffee"]

        a.removeAtIndex(0)
        XCTAssertEqual(["bar", "buzz", "tea", "coffee"], a.elements)

        a.removeAtIndex(2)
        XCTAssertEqual(["bar", "buzz", "coffee"], a.elements)
    }

    func testRemoveAtIndexRxElements() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz", "tea", "coffee"]
        var observed = [[String]]()

        let exp = expectationWithDescription("event emitted")
        a.rx_elements().subscribeNext { (elements) -> Void in
            observed.append(elements)
            if observed.count == 2 {
                exp.fulfill()
            }
        }
        .addDisposableTo(disposeBag)

        a.removeAtIndex(3)

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        XCTAssertEqual(2, observed.count)
        XCTAssertEqual(["foo", "bar", "buzz", "tea", "coffee"], observed[0])
        XCTAssertEqual(["foo", "bar", "buzz", "coffee"], observed[1])
    }

    func testRemoveAtIndexRxEvent() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz", "tea", "coffee"]

        let exp = expectationWithDescription("event emitted")
        a.rx_events().subscribeNext { (event) -> Void in
            XCTAssertEqual([2], event.deletedIndices)
            XCTAssertTrue(event.insertedIndices.isEmpty)
            XCTAssertTrue(event.updatedIndices.isEmpty)
            exp.fulfill()
        }
        .addDisposableTo(disposeBag)

        a.removeAtIndex(2)

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }


    func testRemoveAll() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz", "tea", "coffee"]

        a.removeAll()
        XCTAssertEqual([], a.elements)

        a.removeAll()
        XCTAssertEqual([], a.elements)
    }

    func testRemoveAllRxElements() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz", "tea", "coffee"]
        var observed = [[String]]()

        let exp = expectationWithDescription("event emitted")
        a.rx_elements().subscribeNext { (elements) -> Void in
            observed.append(elements)
            if observed.count == 2 {
                exp.fulfill()
            }
        }
        .addDisposableTo(disposeBag)

        a.removeAll()

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        XCTAssertEqual([], observed[1])
    }

    func testRemoveAllRxEvent() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz", "tea", "coffee"]

        let exp = expectationWithDescription("event emitted")
        a.rx_events().subscribeNext { (event) -> Void in
            XCTAssertEqual([0,1,2,3,4], event.deletedIndices)
            XCTAssertTrue(event.insertedIndices.isEmpty)
            XCTAssertTrue(event.updatedIndices.isEmpty)
            exp.fulfill()
        }
        .addDisposableTo(disposeBag)

        a.removeAll()

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }


    func testInsertContentsOf() {
        var a: ObservableArray<String> = ["foo", "bar"]

        a.insertContentsOf(["buzz", "tea"], atIndex: 1)
        XCTAssertEqual(["foo", "buzz", "tea", "bar"], a.elements)

        a.insertContentsOf([], atIndex: 1)
        XCTAssertEqual(["foo", "buzz", "tea", "bar"], a.elements)

        a.insertContentsOf(["coffee", "milk"], atIndex: 3)
        XCTAssertEqual(["foo", "buzz", "tea", "coffee", "milk", "bar"], a.elements)
    }

    func testInsertContentsOfRxElements() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz"]
        var observed = [[String]]()

        let exp = expectationWithDescription("event emitted")
        a.rx_elements().subscribeNext { (elements) -> Void in
            observed.append(elements)
            if observed.count == 2 {
                exp.fulfill()
            }
        }
        .addDisposableTo(disposeBag)

        a.insertContentsOf(["milk", "coffee", "tea"], atIndex: 2)

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        XCTAssertEqual(["foo", "bar", "milk", "coffee", "tea", "buzz"], observed[1])
    }

    func testInsertContentsOfRxEvent() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz"]

        let exp = expectationWithDescription("event emitted")
        a.rx_events().subscribeNext { (event) -> Void in
            XCTAssertEqual([2,3,4], event.insertedIndices)
            XCTAssertTrue(event.deletedIndices.isEmpty)
            XCTAssertTrue(event.updatedIndices.isEmpty)
            exp.fulfill()
        }
        .addDisposableTo(disposeBag)

        a.insertContentsOf(["milk", "coffee", "tea"], atIndex: 2)

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }



    func testReplaceRange() {
        var a: ObservableArray<String> = ["foo", "bar"]

        a.replaceRange(0...1, with: ["buzz", "tea", "milk", "pot", "sugar"])
        XCTAssertEqual(["buzz", "tea", "milk", "pot", "sugar"], a.elements)

        a.replaceRange(2...3, with: ["lion", "penguin"])
        XCTAssertEqual(["buzz", "tea", "lion", "penguin", "sugar"], a.elements)
    }

    func testReplaceRangeRxElements() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz"]
        var observed = [[String]]()

        let exp = expectationWithDescription("event emitted")
        a.rx_elements().subscribeNext { (elements) -> Void in
            observed.append(elements)
            if observed.count == 2 {
                exp.fulfill()
            }
        }
        .addDisposableTo(disposeBag)

        a.replaceRange(0...1, with: ["milk", "coffee", "tea"])

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        XCTAssertEqual(2, observed.count)
        XCTAssertEqual(["foo", "bar", "buzz"], observed[0])
        XCTAssertEqual(["milk", "coffee", "tea", "buzz"], observed[1])
    }

    func testReplaceRangeRxEvent() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz"]

        let exp = expectationWithDescription("event emitted")
        a.rx_events().subscribeNext { (event) -> Void in
            XCTAssertEqual([1,2,3], event.insertedIndices)
            XCTAssertEqual([1,2], event.deletedIndices)
            XCTAssertTrue(event.updatedIndices.isEmpty)
            exp.fulfill()
        }
        .addDisposableTo(disposeBag)

        a.replaceRange(1...2, with: ["milk", "coffee", "tea"])

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }


    func testPopLast() {
        var a: ObservableArray<String> = ["foo", "bar"]

        XCTAssertEqual("bar", a.popLast())
        XCTAssertEqual(["foo"], a.elements)

        XCTAssertEqual("foo", a.popLast())
        XCTAssertEqual([], a.elements)

        XCTAssertEqual(nil, a.popLast())
        XCTAssertEqual([], a.elements)
    }

    func testPopLastRxElements() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz", "tea"]
        var observed = [[String]]()

        let exp = expectationWithDescription("event emitted")
        a.rx_elements().subscribeNext { (elements) -> Void in
            observed.append(elements)
            if observed.count == 2 {
                exp.fulfill()
            }
        }
        .addDisposableTo(disposeBag)

        a.popLast()

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        XCTAssertEqual(2, observed.count)
        XCTAssertEqual(["foo", "bar", "buzz", "tea"], observed[0])
        XCTAssertEqual(["foo", "bar", "buzz"], observed[1])
    }

    func testPopLastRxEvent() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz", "tea"]

        let exp = expectationWithDescription("event emitted")
        a.rx_events().subscribeNext { (event) -> Void in
            XCTAssertEqual([3], event.deletedIndices)
            XCTAssertTrue(event.insertedIndices.isEmpty)
            XCTAssertTrue(event.updatedIndices.isEmpty)
            exp.fulfill()
        }
        .addDisposableTo(disposeBag)

        a.popLast()

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }


    func testSubscriptIndex() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz"]

        XCTAssertEqual("foo", a[0])
        XCTAssertEqual("bar", a[1])
        XCTAssertEqual("buzz", a[2])

        a[1] = "milk"
        XCTAssertEqual(["foo", "milk", "buzz"], a.elements)

        a[0] = "pot"
        XCTAssertEqual(["pot", "milk", "buzz"], a.elements)
    }

    func testSubscriptIndexRxElements() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz", "tea"]
        var observed = [[String]]()

        let exp = expectationWithDescription("event emitted")
        a.rx_elements().subscribeNext { (elements) -> Void in
            observed.append(elements)
            if observed.count == 2 {
                exp.fulfill()
            }
        }
        .addDisposableTo(disposeBag)

        a[1] = "lion"

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        XCTAssertEqual(2, observed.count)
        XCTAssertEqual(["foo", "bar", "buzz", "tea"], observed[0])
        XCTAssertEqual(["foo", "lion", "buzz", "tea"], observed[1])
    }

    func testSubscriptIndexRxEvent() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz", "tea"]

        let exp = expectationWithDescription("event emitted")
        a.rx_events().subscribeNext { (event) -> Void in
            XCTAssertEqual([1], event.updatedIndices)
            XCTAssertTrue(event.deletedIndices.isEmpty)
            XCTAssertTrue(event.insertedIndices.isEmpty)
            exp.fulfill()
        }
        .addDisposableTo(disposeBag)

        a[1] = "lion"

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }


    func testSubscriptRange() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz"]

        XCTAssertEqual(["foo"], a[0...0])
        XCTAssertEqual(["bar", "buzz"], a[1...2])

        a[0...1] = ["coffee", "tea", "milk", "pot", "sugar"]
        XCTAssertEqual(["coffee", "tea", "milk", "pot", "sugar", "buzz"], a.elements)

        a[1...4] = ["lion", "penguin"]
        XCTAssertEqual(["coffee", "lion", "penguin", "buzz"], a.elements)
    }

    func testSubscriptRangeRxElements() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz"]
        var observed = [[String]]()

        let exp = expectationWithDescription("event emitted")
        a.rx_elements().subscribeNext { (elements) -> Void in
            observed.append(elements)
            if observed.count == 2 {
                exp.fulfill()
            }
        }
        .addDisposableTo(disposeBag)

        a[0...1] = ["milk", "coffee", "tea"]

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        XCTAssertEqual(2, observed.count)
        XCTAssertEqual(["foo", "bar", "buzz"], observed[0])
        XCTAssertEqual(["milk", "coffee", "tea", "buzz"], observed[1])
    }

    func testSubscriptRangeRxEvent() {
        var a: ObservableArray<String> = ["foo", "bar", "buzz"]

        let exp = expectationWithDescription("event emitted")
        a.rx_events().subscribeNext { (event) -> Void in
            XCTAssertEqual([1,2,3], event.insertedIndices)
            XCTAssertEqual([1,2], event.deletedIndices)
            XCTAssertTrue(event.updatedIndices.isEmpty)
            exp.fulfill()
        }
        .addDisposableTo(disposeBag)

        a[1...2] = ["milk", "coffee", "tea"]

        waitForExpectationsWithTimeout(1) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testThreadSafety() {
        var a: ObservableSafeArray<String> = ["foo"]

        let exp = expectationWithDescription("")
        a.rx_events().subscribeNext { _ in }
            .addDisposableTo(disposeBag)

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            for i in 0 ..< 1024 * 1024 {
                a.append("\(i)")
            }
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            for i in 0 ..< 1024 * 1024 {
                a.append("\(i)")
            }
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            for _ in 0 ..< 1024 * 1024 where a.isEmpty {
                if a.isEmpty == false  {
                    a.removeFirst()
                }
            }
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            for _ in 0 ..< 1024 * 1024 where a.count > 1 {
                if a.isEmpty == false  {
                    a.removeFirst(2)
                }
            }
        }

        sleep(9)
        exp.fulfill()

        waitForExpectationsWithTimeout(10) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }
}
