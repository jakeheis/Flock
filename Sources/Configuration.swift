public protocol Configuration {
    func configure()
}

public enum ConfigurationTime {
    case Always
    case Environment(String)
}

extension ConfigurationTime: Hashable {
  public var hashValue: Int {
      switch self {
      case .Always: return "always".hashValue
      case .Environment(let env): return "environment:\(env)".hashValue
      }
  }
}

extension ConfigurationTime: Equatable {}

public func == (lhs: ConfigurationTime, rhs: ConfigurationTime) -> Bool { 
  switch (lhs, rhs) {
    case let (.Always, .Always): return true
    case let (.Environment(e1), .Environment(e2)) where e1 == e2: return true
    default: return false
  }
}
