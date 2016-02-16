
[![TravisCI](http://img.shields.io/travis/safx/ObservableArray-RxSwift.svg?style=flat)](https://travis-ci.org/safx/ObservableArray-RxSwift)
[![codecov.io](https://codecov.io/github/safx/ObservableArray-RxSwift/coverage.svg?branch=master)](https://codecov.io/github/safx/ObservableArray-RxSwift?branch=master)
![Platform](https://img.shields.io/cocoapods/p/ObservableArray-RxSwift.svg?style=flat)
![License](https://img.shields.io/cocoapods/l/ObservableArray-RxSwift.svg?style=flat)
![Version](https://img.shields.io/cocoapods/v/ObservableArray-RxSwift.svg?style=flat)
![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)

# ObservableArray-RxSwift

ObservableArray is an array that can emit messages of elements and diffs on it's changing.

## Usage

`ObservableArray` has two `Observable`s:

```swift
func rx_elements() -> Observable<[Element]>
func rx_events() -> Observable<ArrayChangeEvent>
```

### `rx_elements`

`rx_elements()` emits own elements on its changing.

```swift
var array: ObservableArray<String> = ["foo", "bar", "buzz"]
array.rx_events().subscribeNext { print($0) }

array.append("coffee")
array[2] = "milk"
array.removeAll()
```

This will print:

    ["foo", "bar", "buzz", "coffee"]
    ["foo", "bar", "milk", "coffee"]
    []

`rx_elements` can be worked with `rx_itemsWithCellIdentifier`:

```swift
model.rx_elements()
    .observeOn(MainScheduler.instance)
    .bindTo(tableView.rx_itemsWithCellIdentifier("MySampleCell")) { (row, element, cell) in
        guard let c = cell as? MySampleCell else { return }
        c.model = self.model[row]
        return
    }
    .addDisposableTo(disposeBag)
```

### `rx_events`

`rx_events()` emits `ArrayChangeEvent` that contains indeces of diff on its changing.

```swift
var array: ObservableArray<String> = ["foo", "bar", "buzz"]
array.rx_events().subscribeNext { print($0) }

array.append("coffee")
array[2] = "milk"
array.removeAll()
```

This will print:

    ArrayChangeEvent(insertedIndeces: [3], deletedIndeces: [], updatedIndeces: [])
    ArrayChangeEvent(insertedIndeces: [], deletedIndeces: [], updatedIndeces: [2])
    ArrayChangeEvent(insertedIndeces: [], deletedIndeces: [0, 1, 2, 3], updatedIndeces: [])

`ArrayChangeEvent` is defined as follows:

```swift
struct ArrayChangeEvent {
    let insertedIndeces: [Int]
    let deletedIndeces: [Int]
    let updatedIndeces: [Int]
}
```

These indeces can be used with methods of table view such like `insertRowsAtIndexPaths`.
The following code will enable cell animations on its changing.

```swift
extension UITableView {
    public func rx_autoUpdater(source: Observable<ArrayChangeEvent>) -> Disposable {
        return source
            .scan((0, nil)) { (a: (Int, ArrayChangeEvent!), ev) in
                return (a.0 + ev.insertedIndeces.count - ev.deletedIndeces.count, ev)
            }
            .observeOn(MainScheduler.instance)
            .subscribeNext { sourceCount, event in
                guard let event = event else { return }

                let tableCount = self.numberOfRowsInSection(0)
                guard tableCount + event.insertedIndeces.count - event.deletedIndeces.count == sourceCount else {
                    self.reloadData()
                    return
                }

                func toIndexSet(array: [Int]) -> [NSIndexPath] {
                    return array.map { NSIndexPath(forRow: $0, inSection: 0) }
                }

                self.beginUpdates()
                self.insertRowsAtIndexPaths(toIndexSet(event.insertedIndeces), withRowAnimation: .Automatic)
                self.deleteRowsAtIndexPaths(toIndexSet(event.deletedIndeces), withRowAnimation: .Automatic)
                self.reloadRowsAtIndexPaths(toIndexSet(event.updatedIndeces), withRowAnimation: .Automatic)
                self.endUpdates()
            }
    }
}
```

You can use `rx_autoUpdater` with `bindTo` in your view contollers:

```swift
model.rx_events()
    .observeOn(MainScheduler.instance)
    .bindTo(tableView.rx_autoUpdater)
    .addDisposableTo(disposeBag)
```

Unfortunately, `rx_autoUpdater` doesn't work with `rx_elements()` binding to `rx_itemsWithCellIdentifier`, because it uses `reloadData()` internally.

## Supported Methods

ObservableArray implements the following methods and properties, which just work as the equivallent of an array's one.
You can use other methods defined in protocol extensions such as `sort`, `reverse` and `enumerate`.

```swift
init()
init(count:Int, repeatedValue: Element)
init<S : SequenceType where S.Generator.Element == Element>(_ s: S)
init(arrayLiteral elements: Element...)

var startIndex: Int
var endIndex: Int
var capacity: Int

func reserveCapacity(minimumCapacity: Int)
func append(newElement: Element)
func appendContentsOf<S : SequenceType where S.Generator.Element == Element>(newElements: S)
func appendContentsOf<C : CollectionType where C.Generator.Element == Element>(newElements: C)
func removeLast() -> Element
func insert(newElement: Element, atIndex i: Int)
func removeAtIndex(index: Int) -> Element
func removeAll(keepCapacity: Bool = false)
func insertContentsOf(newElements: [Element], atIndex i: Int)
func replaceRange<C : CollectionType where C.Generator.Element == Element>(subRange: Range<Int>, with newCollection: C)
func popLast() -> Element?

var description: String
var debugDescription: String

subscript(index: Int) -> Element
subscript(bounds: Range<Int>) -> ArraySlice<Element>
```

## Install

### CocoaPods

    pod 'ObservableArray-RxSwift'

### Carthage

    github "safx/ObservableArray-RxSwift"

### Manual Install

Just copy `ObservableArray.swift` into your project.


## License

MIT
