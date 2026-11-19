import Darwin

/// Resolves undocumented C functions at runtime instead of linking them, so a symbol
/// removed in a future macOS release disables one feature instead of crashing at launch.
enum PrivateSymbol {
    static func load<T>(_ name: String, from library: String, as type: T.Type) -> T? {
        guard let handle = dlopen(library, RTLD_LAZY | RTLD_NOLOAD) ?? dlopen(library, RTLD_LAZY),
              let symbol = dlsym(handle, name) else { return nil }
        return unsafeBitCast(symbol, to: type)
    }

    static let iokit = "/System/Library/Frameworks/IOKit.framework/IOKit"
}
