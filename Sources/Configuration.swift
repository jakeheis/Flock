public protocol Configuration {
    func configure()
}

public enum ConfigurationTime {
    case always
    case env(String)
}

extension ConfigurationTime: Hashable {
  public var hashValue: Int {
      switch self {
      case .always: return "always".hashValue
      case .env(let env): return "environment:\(env)".hashValue
      }
  }
}

extension ConfigurationTime: Equatable {}

public func == (lhs: ConfigurationTime, rhs: ConfigurationTime) -> Bool { 
  switch (lhs, rhs) {
    case (.always, .always): return true
    case let (.env(e1), .env(e2)) where e1 == e2: return true
    default: return false
  }
}
