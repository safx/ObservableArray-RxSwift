//
//  ObservableArray.swift
//  ObservableArray
//
//  Created by Safx Developer on 2015/02/19.
//  Copyright (c) 2016 Safx Developers. All rights reserved.
//

import Foundation
import RxSwift

public struct ArrayChangeEvent {
    public let insertedIndices: [Int]
    public let deletedIndices: [Int]
    public let updatedIndices: [Int]

    private init(inserted: [Int] = [], deleted: [Int] = [], updated: [Int] = []) {
        assert(inserted.count + deleted.count + updated.count > 0)
        self.insertedIndices = inserted
        self.deletedIndices = deleted
        self.updatedIndices = updated
    }
}

public protocol ObservableArrayType {
    associatedtype Element
    associatedtype Lock: LockType

    var eventSubject: PublishSubject<ArrayChangeEvent>! { set get }
    var elementsSubject: BehaviorSubject<[Element]>! { set get }
    var elements: [Element] { set get }

    var lock: Lock { get }
}


public struct ObservableArrayBase<E, L: LockType>: ObservableArrayType, ArrayLiteralConvertible {
    public typealias Element = E
    public typealias Lock = L

    public var eventSubject: PublishSubject<ArrayChangeEvent>!
    public var elementsSubject: BehaviorSubject<[Element]>!
    public var elements: [Element]

    public var lock = Lock()

    public init() {
        self.elements = []
    }

    public init(count:Int, repeatedValue: Element) {
        self.elements = Array(count: count, repeatedValue: repeatedValue)
    }

    public init<S : SequenceType where S.Generator.Element == Element>(_ s: S) {
        self.elements = Array(s)
    }

    public init(arrayLiteral elements: Element...) {
        self.elements = elements
    }
}

public struct ObservableArray<E>: ObservableArrayType, ArrayLiteralConvertible {
    public typealias Element = E
    public typealias Lock = NullLock

    public var eventSubject: PublishSubject<ArrayChangeEvent>!
    public var elementsSubject: BehaviorSubject<[Element]>!
    public var elements: [Element]

    public var lock = Lock()

    public init() {
        self.elements = []
    }

    public init(count:Int, repeatedValue: Element) {
        self.elements = Array(count: count, repeatedValue: repeatedValue)
    }

    public init<S : SequenceType where S.Generator.Element == Element>(_ s: S) {
        self.elements = Array(s)
    }

    public init(arrayLiteral elements: Element...) {
        self.elements = elements
    }
}

public struct ObservableSafeArray<E>: ObservableArrayType, ArrayLiteralConvertible {
    public typealias Element = E
    public typealias Lock = Semaphore

    public var eventSubject: PublishSubject<ArrayChangeEvent>!
    public var elementsSubject: BehaviorSubject<[Element]>!
    public var elements: [Element]

    public var lock = Lock()

    public init() {
        self.elements = []
    }

    public init(count:Int, repeatedValue: Element) {
        self.elements = Array(count: count, repeatedValue: repeatedValue)
    }

    public init<S : SequenceType where S.Generator.Element == Element>(_ s: S) {
        self.elements = Array(s)
    }

    public init(arrayLiteral elements: Element...) {
        self.elements = elements
    }
}





extension ObservableArrayType {
    public mutating func rx_elements() -> Observable<[Element]> {
        if elementsSubject == nil {
            self.elementsSubject = BehaviorSubject<[Element]>(value: self.elements)
        }
        return elementsSubject
    }

    public mutating func rx_events() -> Observable<ArrayChangeEvent> {
        if eventSubject == nil {
            self.eventSubject = PublishSubject<ArrayChangeEvent>()
        }
        return eventSubject
    }

    private func arrayDidChange(event: ArrayChangeEvent) {
        elementsSubject?.onNext(elements)
        eventSubject?.onNext(event)
    }
}

extension ObservableArrayType {
    public var startIndex: Int {
        lock.lock()
        let i = elements.startIndex
        lock.unlock()
        return i
    }

    public var endIndex: Int {
        lock.lock()
        let i = elements.endIndex
        lock.unlock()
        return i
    }
}

extension ObservableArrayType {

    public var isEmpty: Bool {
        lock.lock()
        let b = elements.isEmpty
        lock.unlock()
        return b
    }

    public var count: Int {
        lock.lock()
        let c = elements.count
        lock.unlock()
        return c
    }

    public var capacity: Int {
        lock.lock()
        let c = elements.capacity
        lock.unlock()
        return c
    }

    public mutating func reserveCapacity(minimumCapacity: Int) {
        lock.lock()
        elements.reserveCapacity(minimumCapacity)
        lock.unlock()
    }

    public mutating func append(newElement: Element) {
        lock.lock()
        elements.append(newElement)
        arrayDidChange(ArrayChangeEvent(inserted: [elements.count - 1]))
        lock.unlock()
    }

    public mutating func appendContentsOf<S : SequenceType where S.Generator.Element == Element>(newElements: S) {
        lock.lock()
        let end = elements.count
        elements.appendContentsOf(newElements)
        if end != elements.count {
            arrayDidChange(ArrayChangeEvent(inserted: Array(end..<elements.count)))
        }
        lock.unlock()
    }

    public mutating func appendContentsOf<C : CollectionType where C.Generator.Element == Element>(newElements: C) {
        lock.lock()
        if !newElements.isEmpty {
            let end = elements.count
            elements.appendContentsOf(newElements)
            arrayDidChange(ArrayChangeEvent(inserted: Array(end..<elements.count)))
        }
        lock.unlock()
    }

    public mutating func removeFirst() -> Element {
        lock.lock()
        let e = elements.removeFirst()
        arrayDidChange(ArrayChangeEvent(deleted: [elements.count]))
        lock.unlock()
        return e
    }

    public mutating func removeFirst(n: Int) {
        lock.lock()
        elements.removeFirst(n)
        arrayDidChange(ArrayChangeEvent(deleted: [elements.count]))
        lock.unlock()
    }

    public mutating func removeLast() -> Element {
        lock.lock()
        let e = elements.removeLast()
        arrayDidChange(ArrayChangeEvent(deleted: [elements.count]))
        lock.unlock()
        return e
    }

    public mutating func removeLast(n: Int) {
        lock.lock()
        elements.removeLast(n)
        arrayDidChange(ArrayChangeEvent(deleted: [elements.count]))
        lock.unlock()
    }

    public mutating func insert(newElement: Element, atIndex i: Int) {
        lock.lock()
        elements.insert(newElement, atIndex: i)
        arrayDidChange(ArrayChangeEvent(inserted: [i]))
        lock.unlock()
    }

    public mutating func removeAtIndex(index: Int) -> Element {
        lock.lock()
        let e = elements.removeAtIndex(index)
        arrayDidChange(ArrayChangeEvent(deleted: [index]))
        lock.unlock()
        return e
    }

    public mutating func removeAll(keepCapacity: Bool = false) {
        lock.lock()
        if !elements.isEmpty {
            let es = elements
            elements.removeAll(keepCapacity: keepCapacity)
            arrayDidChange(ArrayChangeEvent(deleted: Array(0..<es.count)))
        }
        lock.unlock()
    }

    public mutating func insertContentsOf(newElements: [Element], atIndex i: Int) {
        lock.lock()
        if !newElements.isEmpty {
            elements.insertContentsOf(newElements, at: i)
            arrayDidChange(ArrayChangeEvent(inserted: Array(i..<i + newElements.count)))
        }
        lock.unlock()
    }

    public mutating func replaceRange<C : CollectionType where C.Generator.Element == Element>(subRange: Range<Int>, with newCollection: C) {
        lock.lock()
        let oldCount = elements.count
        elements.replaceRange(subRange, with: newCollection)
        if let first = subRange.first {
            let newCount = elements.count
            let end = first + (newCount - oldCount) + subRange.count
            arrayDidChange(ArrayChangeEvent(inserted: Array(first..<end),
                                            deleted: Array(subRange)))
        }
        lock.unlock()
    }

    public mutating func popLast() -> Element? {
        lock.lock()
        let e = elements.popLast()
        if e != nil {
            arrayDidChange(ArrayChangeEvent(deleted: [elements.count]))
        }
        lock.unlock()
        return e
    }
}

extension ObservableArrayType {
    public var description: String {
        lock.lock()
        let d = elements.description
        lock.unlock()
        return d
    }
}

extension ObservableArray {
    public var debugDescription: String {
        lock.lock()
        let d = elements.debugDescription
        lock.unlock()
        return d
    }
}

extension ObservableArray {
    public subscript(index: Int) -> Element {
        get {
            lock.lock()
            let e = elements[index]
            lock.unlock()
            return e
        }
        set {
            lock.lock()
            elements[index] = newValue
            if index == elements.count {
                arrayDidChange(ArrayChangeEvent(inserted: [index]))
            } else {
                arrayDidChange(ArrayChangeEvent(updated: [index]))
            }
            lock.unlock()
        }
    }

    public subscript(bounds: Range<Int>) -> ArraySlice<Element> {
        get {
            lock.lock()
            let es = elements[bounds]
            lock.unlock()
            return es
        }
        set {
            lock.lock()
            elements[bounds] = newValue
            guard let first = bounds.first else {
                return
            }
            arrayDidChange(ArrayChangeEvent(inserted: Array(first..<first + newValue.count),
                                             deleted: Array(bounds)))
            lock.unlock()
        }
    }
}



public protocol LockType {
    init()
    func lock()
    func unlock()
}

public struct NullLock: LockType {
    public init() {}
    public func lock() {}
    public func unlock() {}
}

public struct Lock: LockType {
    private let lockObject: NSLock

    public init() {
        lockObject = NSLock()
    }
    public func lock() {
        lockObject.lock()
    }
    public func unlock() {
        lockObject.unlock()
    }
}

public struct Semaphore: LockType {
    private let semaphore: dispatch_semaphore_t

    public init() {
        semaphore = dispatch_semaphore_create(1)
    }
    public func lock() {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    public func unlock() {
        dispatch_semaphore_signal(semaphore)
    }
}
