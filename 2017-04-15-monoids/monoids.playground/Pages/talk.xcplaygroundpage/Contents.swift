
protocol Semigroup {
  func op(_ s: Self) -> Self
}

extension Int: Semigroup {
  func op(_ s: Int) -> Int {
    return self + s
  }
}

extension Array: Semigroup {
  func op(_ s: Array) -> Array<Element> {
    return self + s
  }
}

extension String: Semigroup {
  func op(_ s: String) -> String {
    return self + s
  }
}

extension Bool: Semigroup {
  func op(_ s: Bool) -> Bool {
    return self && s
  }
}

precedencegroup SemigroupPrecedence {
  associativity: right
}

infix operator <> : SemigroupPrecedence

func <> <S: Semigroup> (lhs: S, rhs: S) -> S {
  return lhs.op(rhs)
}

1 <> 2
[1, 2, 3] <> [4, 5, 6]

func sconcat <S: Semigroup> (_ xs: [S], _ initial: S) -> S {
  return xs.reduce(initial, <>)
}

sconcat([1, 2, 3], 0)
sconcat([[1, 2, 3], [3, 4, 5], [5, 6, 7]], [])

protocol Monoid: Semigroup {
  static var e: Self { get }
}

extension Int: Monoid {
  static let e = 0
}

extension Array: Monoid {
  static var e: Array {
    return []
  }
}

extension String: Monoid {
  static let e = ""
}

extension Bool: Monoid {
  static let e = true
}

func mconcat <M: Monoid> (_ xs: [M]) -> M {
  return xs.reduce(M.e, <>)
}

mconcat([1, 2, 3, 4])
mconcat([[1, 2, 3], [4, 5, 6]])

struct Endo<A>: Monoid {
  let call: (A) -> A

  static var e: Endo {
    return Endo { x in x }
  }

  func op(_ s: Endo) -> Endo {
    return Endo { x in
      return s.call(self.call(x))
    }
  }
}

let square: Endo<Int> = Endo { $0 * $0 }
let incr = Endo { $0 + 1 }
let mod3 = Endo { $0 % 3 }

mconcat([square, incr, mod3]).call(2)

struct Function <A, B> {
}

struct FunctionM<A, M: Monoid>: Monoid {
  let call: (A) -> M

  func op(_ s: FunctionM) -> FunctionM {
    return FunctionM { x in
      return self.call(x) <> s.call(x)
    }
  }
  static var e: FunctionM {
    return FunctionM { _ in M.e }
  }
}

typealias Predicate<A> = FunctionM<A, Bool>

let isEven = Predicate<Int> { $0 % 2 == 0 }
let isLessThan10 = Predicate<Int> { $0 < 10 }
//let isLessThan = { x in Predicate<Int> { $0 < x } }

func isLessThan <C: Comparable> (_ x: C) -> Predicate<C> {
  return Predicate { $0 < x }
}

isEven <> isLessThan10

extension Sequence {
  func filtered(by predicate: Predicate<Iterator.Element>) -> [Iterator.Element] {
    return self.filter { predicate.call($0) }
  }
}

Array(0...200).filtered(by: isEven <> isLessThan10)
Array(0...200).filtered(by: isEven <> isLessThan(10))
["foo", "bar", "baz", "qux"]
  .filtered(by: isLessThan("f"))

enum Ordering: Monoid {
  case lt
  case eq
  case gt

  func op(_ s: Ordering) -> Ordering {
    switch (self, s) {
    case (.lt, _): return .lt
    case (.gt, _): return .gt
    case (.eq, _): return s
    }
  }

  static let e = Ordering.eq
}

typealias Comparator<A> = FunctionM<(A, A), Ordering>

extension Comparable {
  static func comparator() -> Comparator<Self> {
    return Comparator.init { $0 < $1 ? .lt : $0 > $1 ? .gt : .eq }
  }
}

Int.comparator()

extension Array {
  func sorted(by comparator: Comparator<Element>) -> Array {
    return self.sorted { comparator.call($0, $1) == .lt }
  }
}

[4, 6, 2, 8, 1, 2].sorted(by: Int.comparator())

extension Ordering {
  func reversed() -> Ordering {
    return self == .lt ? .gt : self == .gt ? .lt : .eq
  }
}

// Should work but doesnt 
// ----------------------
//extension Comparator {
//  func reversed() -> Comparator {
//    return Comparator { pair in
//      self.f(pair).reversed()
//    }
//  }
//}

extension FunctionM where M == Ordering {
  func reversed() -> FunctionM {
    return FunctionM.init { self.call($0).reversed() }
  }
}

Int.comparator().reversed()

[4, 6, 2, 8, 1, 2].sorted(by: Int.comparator().reversed())

extension Lens where Part: Comparable {
  var comparator: Comparator<Whole> {
    return Comparator { lhs, rhs in
      self.view(lhs) < self.view(rhs) ? .lt
        : self.view(lhs) > self.view(rhs) ? .gt
        : .eq
    }
  }
}

Project.lens.creator.location.name.comparator

let comparators = [
  Project.lens.state.comparator,
  Project.lens.creator.location.name.comparator,
  Project.lens.name.comparator
]

projects
  .sorted(by: mconcat(comparators))
  .map { "\($0.state) : \($0.creator.location.name) : \($0.name)" }





"done"









