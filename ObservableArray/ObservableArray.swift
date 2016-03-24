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
    public let insertedIndeces: [Int]
    public let deletedIndeces: [Int]
    public let updatedIndeces: [Int]

    private init(inserted: [Int] = [], deleted: [Int] = [], updated: [Int] = []) {
        assert(inserted.count + deleted.count + updated.count > 0)
        self.insertedIndeces = inserted
        self.deletedIndeces = deleted
        self.updatedIndeces = updated
    }
}

public struct ObservableArray<Element>: ArrayLiteralConvertible {
    public typealias EventType = ArrayChangeEvent

    internal var eventSubject: PublishSubject<EventType>!
    internal var elementsSubject: PublishSubject<[Element]>!
    internal var elements: [Element]

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

extension ObservableArray {
    public mutating func rx_elements() -> Observable<[Element]> {
        if elementsSubject == nil {
            self.elementsSubject = PublishSubject<[Element]>()
        }
        return elementsSubject
    }

    public mutating func rx_events() -> Observable<EventType> {
        if eventSubject == nil {
            self.eventSubject = PublishSubject<EventType>()
        }
        return eventSubject
    }

    private func arrayDidChanged(event: EventType) {
        elementsSubject?.on(.Next(self.elements))
        eventSubject?.on(.Next(event))
    }
}

extension ObservableArray: Indexable {
    public var startIndex: Int {
        return elements.startIndex
    }

    public var endIndex: Int {
        return elements.endIndex
    }
}

extension ObservableArray: RangeReplaceableCollectionType {
    public var capacity: Int {
        return elements.capacity
    }

    public mutating func reserveCapacity(minimumCapacity: Int) {
        elements.reserveCapacity(minimumCapacity)
    }

    public mutating func append(newElement: Element) {
        elements.append(newElement)
        arrayDidChanged(ArrayChangeEvent(inserted: [elements.count - 1]))
    }

    public mutating func appendContentsOf<S : SequenceType where S.Generator.Element == Element>(newElements: S) {
        let end = elements.count
        elements.appendContentsOf(newElements)
        guard end != elements.count else {
            return
        }
        arrayDidChanged(ArrayChangeEvent(inserted: Array(end..<elements.count)))
    }

    public mutating func appendContentsOf<C : CollectionType where C.Generator.Element == Element>(newElements: C) {
        guard !newElements.isEmpty else {
            return
        }
        let end = elements.count
        elements.appendContentsOf(newElements)
        arrayDidChanged(ArrayChangeEvent(inserted: Array(end..<elements.count)))
    }

    public mutating func removeLast() -> Element {
        let e = elements.removeLast()
        arrayDidChanged(ArrayChangeEvent(deleted: [elements.count]))
        return e
    }

    public mutating func insert(newElement: Element, atIndex i: Int) {
        elements.insert(newElement, atIndex: i)
        arrayDidChanged(ArrayChangeEvent(inserted: [i]))
    }

    public mutating func removeAtIndex(index: Int) -> Element {
        let e = elements.removeAtIndex(index)
        arrayDidChanged(ArrayChangeEvent(deleted: [index]))
        return e
    }

    public mutating func removeAll(keepCapacity: Bool = false) {
        guard !elements.isEmpty else {
            return
        }
        let es = elements
        elements.removeAll(keepCapacity: keepCapacity)
        arrayDidChanged(ArrayChangeEvent(deleted: Array(0..<es.count)))
    }

    public mutating func insertContentsOf(newElements: [Element], atIndex i: Int) {
        guard !newElements.isEmpty else {
            return
        }
        elements.insertContentsOf(newElements, at: i)
        arrayDidChanged(ArrayChangeEvent(inserted: Array(i..<i + newElements.count)))
    }

    public mutating func replaceRange<C : CollectionType where C.Generator.Element == Element>(subRange: Range<Int>, with newCollection: C) {
        let oldCount = elements.count
        elements.replaceRange(subRange, with: newCollection)
        guard let first = subRange.first else {
            return
        }
        let newCount = elements.count
        let end = first + (newCount - oldCount) + subRange.count
        arrayDidChanged(ArrayChangeEvent(inserted: Array(first..<end),
                                         deleted: Array(subRange)))
    }

    public mutating func popLast() -> Element? {
        let e = elements.popLast()
        if e != nil {
            arrayDidChanged(ArrayChangeEvent(deleted: [elements.count]))
        }
        return e
    }
}

extension ObservableArray: CustomDebugStringConvertible {
    public var description: String {
        return elements.description
    }
}

extension ObservableArray: CustomStringConvertible {
    public var debugDescription: String {
        return elements.debugDescription
    }
}

extension ObservableArray: CollectionType {
    public subscript(index: Int) -> Element {
        get {
            return elements[index]
        }
        set {
            elements[index] = newValue
            if index == elements.count {
                arrayDidChanged(ArrayChangeEvent(inserted: [index]))
            } else {
                arrayDidChanged(ArrayChangeEvent(updated: [index]))
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
            arrayDidChanged(ArrayChangeEvent(inserted: Array(first..<first + newValue.count),
                                             deleted: Array(bounds)))
        }
    }
}
