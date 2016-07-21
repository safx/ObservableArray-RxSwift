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

    var eventSubject: PublishSubject<ArrayChangeEvent>! { set get }
    var elementsSubject: BehaviorSubject<[Element]>! { set get }
    var elements: [Element] { set get }
}

public struct ObservableArray<Element>: ObservableArrayType, ArrayLiteralConvertible {
    public var eventSubject: PublishSubject<ArrayChangeEvent>!
    public var elementsSubject: BehaviorSubject<[Element]>!
    public var elements: [Element]

    public init() {
        elements = []
    }

    public init(count: Int, repeatedValue: Element) {
        elements = Array(count: count, repeatedValue: repeatedValue)
    }

    public init<S : SequenceType where S.Generator.Element == Element>(_ s: S) {
        elements = Array(s)
    }

    public init(arrayLiteral elements: Element...) {
        self.elements = elements
    }
}

public class ObservableArrayClass<Element>: ObservableArrayType, ArrayLiteralConvertible {
    public var eventSubject: PublishSubject<ArrayChangeEvent>!
    public var elementsSubject: BehaviorSubject<[Element]>!
    public var elements: [Element]

    public init() {
        elements = []
    }

    public init(count:Int, repeatedValue: Element) {
        elements = Array(count: count, repeatedValue: repeatedValue)
    }

    public init<S : SequenceType where S.Generator.Element == Element>(_ s: S) {
        elements = Array(s)
    }

    public required init(arrayLiteral elements: Element...) {
        self.elements = elements
    }
}

extension ObservableArrayType {
    public mutating func rx_elements() -> Observable<[Element]> {
        if elementsSubject == nil {
            elementsSubject = BehaviorSubject<[Element]>(value: self.elements)
        }
        return elementsSubject
    }

    public mutating func rx_events() -> Observable<ArrayChangeEvent> {
        if eventSubject == nil {
            eventSubject = PublishSubject<ArrayChangeEvent>()
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
        return elements.startIndex
    }

    public var endIndex: Int {
        return elements.endIndex
    }
}

extension ObservableArrayType {

    public var capacity: Int {
        return elements.capacity
    }

    public mutating func reserveCapacity(minimumCapacity: Int) {
        elements.reserveCapacity(minimumCapacity)
    }

    public mutating func append(newElement: Element) {
        elements.append(newElement)
        arrayDidChange(ArrayChangeEvent(inserted: [elements.count - 1]))
    }

    public mutating func appendContentsOf<S : SequenceType where S.Generator.Element == Element>(newElements: S) {
        let end = elements.count
        elements.appendContentsOf(newElements)
        guard end != elements.count else {
            return
        }
        arrayDidChange(ArrayChangeEvent(inserted: Array(end..<elements.count)))
    }

    public mutating func appendContentsOf<C : CollectionType where C.Generator.Element == Element>(newElements: C) {
        guard !newElements.isEmpty else {
            return
        }
        let end = elements.count
        elements.appendContentsOf(newElements)
        arrayDidChange(ArrayChangeEvent(inserted: Array(end..<elements.count)))
    }

    public mutating func removeLast() -> Element {
        let e = elements.removeLast()
        arrayDidChange(ArrayChangeEvent(deleted: [elements.count]))
        return e
    }

    public mutating func insert(newElement: Element, atIndex i: Int) {
        elements.insert(newElement, atIndex: i)
        arrayDidChange(ArrayChangeEvent(inserted: [i]))
    }

    public mutating func removeAtIndex(index: Int) -> Element {
        let e = elements.removeAtIndex(index)
        arrayDidChange(ArrayChangeEvent(deleted: [index]))
        return e
    }

    public mutating func removeAll(keepCapacity: Bool = false) {
        guard !elements.isEmpty else {
            return
        }
        let es = elements
        elements.removeAll(keepCapacity: keepCapacity)
        arrayDidChange(ArrayChangeEvent(deleted: Array(0..<es.count)))
    }

    public mutating func insertContentsOf(newElements: [Element], atIndex i: Int) {
        guard !newElements.isEmpty else {
            return
        }
        elements.insertContentsOf(newElements, at: i)
        arrayDidChange(ArrayChangeEvent(inserted: Array(i..<i + newElements.count)))
    }

    public mutating func replaceRange<C : CollectionType where C.Generator.Element == Element>(subRange: Range<Int>, with newCollection: C) {
        let oldCount = elements.count
        elements.replaceRange(subRange, with: newCollection)
        guard let first = subRange.first else {
            return
        }
        let newCount = elements.count
        let end = first + (newCount - oldCount) + subRange.count
        arrayDidChange(ArrayChangeEvent(inserted: Array(first..<end),
                                         deleted: Array(subRange)))
    }

    public mutating func popLast() -> Element? {
        let e = elements.popLast()
        if e != nil {
            arrayDidChange(ArrayChangeEvent(deleted: [elements.count]))
        }
        return e
    }
}

extension ObservableArrayType {
    public var description: String {
        return elements.description
    }
}

extension ObservableArrayType {
    public var debugDescription: String {
        return elements.debugDescription
    }
}

extension ObservableArrayType {
    public subscript(index: Int) -> Element {
        get {
            return elements[index]
        }
        set {
            elements[index] = newValue
            if index == elements.count {
                arrayDidChange(ArrayChangeEvent(inserted: [index]))
            } else {
                arrayDidChange(ArrayChangeEvent(updated: [index]))
            }
        }
    }

    public subscript(bounds: Range<Int>) -> ArraySlice<Element> {
        get {
            return elements[bounds]
        }
        set {
            elements[bounds] = newValue
            guard let first = bounds.first else {
                return
            }
            arrayDidChange(ArrayChangeEvent(inserted: Array(first..<first + newValue.count),
                                             deleted: Array(bounds)))
        }
    }
}
