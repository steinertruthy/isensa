import Foundation

/// One channel of an IOReport delta sample.
public struct IOReportChannel: Sendable, Equatable {
    public enum Value: Sendable, Equatable {
        /// Accumulated counter delta (e.g. energy in the channel's unit).
        case simple(Int64)
        /// Time spent in each state during the interval (performance states, idle…).
        case states([State])
        case unsupported
    }

    public struct State: Sendable, Equatable {
        public let name: String
        public let residency: Int64
    }

    public let group: String
    public let subgroup: String
    public let name: String
    /// Unit label reported by the driver, e.g. `mJ`, `nJ`.
    public let unit: String?
    public let value: Value

    public init(group: String, subgroup: String, name: String, unit: String?, value: Value) {
        self.group = group
        self.subgroup = subgroup
        self.name = name
        self.unit = unit
        self.value = value
    }
}

/// ⚠️ PRIVATE INTERFACE — `libIOReport` (undocumented), resolved at runtime.
///
/// Subscribes to channel groups and returns deltas between consecutive samples.
/// Requires no privileges. Not thread-safe; own it from a single actor.
public final class IOReportSampler {
    private typealias CopyChannelsInGroup = @convention(c) (CFString?, CFString?, UInt64, UInt64, UInt64) -> Unmanaged<CFMutableDictionary>?
    private typealias MergeChannels = @convention(c) (CFMutableDictionary, CFMutableDictionary, CFTypeRef?) -> Void
    private typealias CreateSubscription = @convention(c) (
        UnsafeMutableRawPointer?, CFMutableDictionary, UnsafeMutablePointer<Unmanaged<CFMutableDictionary>?>, UInt64, CFTypeRef?
    ) -> Unmanaged<AnyObject>?
    private typealias CreateSamples = @convention(c) (AnyObject, CFMutableDictionary, CFTypeRef?) -> Unmanaged<CFDictionary>?
    private typealias CreateSamplesDelta = @convention(c) (CFDictionary, CFDictionary, CFTypeRef?) -> Unmanaged<CFDictionary>?
    private typealias ChannelString = @convention(c) (CFDictionary) -> Unmanaged<CFString>?
    private typealias ChannelInt32 = @convention(c) (CFDictionary) -> Int32
    private typealias SimpleValue = @convention(c) (CFDictionary, Int32) -> Int64
    private typealias StateName = @convention(c) (CFDictionary, Int32) -> Unmanaged<CFString>?
    private typealias StateResidency = @convention(c) (CFDictionary, Int32) -> Int64

    private struct Symbols {
        let createSamples: CreateSamples
        let createSamplesDelta: CreateSamplesDelta
        let group: ChannelString
        let subgroup: ChannelString
        let name: ChannelString
        let unit: ChannelString
        let format: ChannelInt32
        let simpleValue: SimpleValue
        let stateCount: ChannelInt32
        let stateName: StateName
        let stateResidency: StateResidency
    }

    private static let library = "/usr/lib/libIOReport.dylib"
    private let symbols: Symbols
    private let subscription: AnyObject
    private let channels: CFMutableDictionary
    private var previous: (sample: CFDictionary, date: Date)?

    /// Subscribes to the given `(group, subgroup)` pairs (`nil` subgroup = whole group).
    /// Returns `nil` when the library or any group is unavailable.
    public init?(groups: [(group: String, subgroup: String?)]) {
        func load<T>(_ name: String, _ type: T.Type) -> T? { PrivateSymbol.load(name, from: Self.library, as: type) }
        guard let copyChannels = load("IOReportCopyChannelsInGroup", CopyChannelsInGroup.self),
              let merge = load("IOReportMergeChannels", MergeChannels.self),
              let subscribe = load("IOReportCreateSubscription", CreateSubscription.self),
              let createSamples = load("IOReportCreateSamples", CreateSamples.self),
              let createDelta = load("IOReportCreateSamplesDelta", CreateSamplesDelta.self),
              let group = load("IOReportChannelGetGroup", ChannelString.self),
              let subgroup = load("IOReportChannelGetSubGroup", ChannelString.self),
              let name = load("IOReportChannelGetChannelName", ChannelString.self),
              let unit = load("IOReportChannelGetUnitLabel", ChannelString.self),
              let format = load("IOReportChannelGetFormat", ChannelInt32.self),
              let simpleValue = load("IOReportSimpleGetIntegerValue", SimpleValue.self),
              let stateCount = load("IOReportStateGetCount", ChannelInt32.self),
              let stateName = load("IOReportStateGetNameForIndex", StateName.self),
              let stateResidency = load("IOReportStateGetResidency", StateResidency.self),
              !groups.isEmpty else { return nil }

        var merged: CFMutableDictionary?
        for entry in groups {
            guard let channels = copyChannels(entry.group as CFString, entry.subgroup as CFString?, 0, 0, 0)?.takeRetainedValue() else {
                return nil
            }
            if let merged { merge(merged, channels, nil) } else { merged = channels }
        }
        guard let merged else { return nil }

        var subscribed: Unmanaged<CFMutableDictionary>?
        guard let subscription = subscribe(nil, merged, &subscribed, 0, nil)?.takeRetainedValue(),
              let subscribedChannels = subscribed?.takeRetainedValue() else { return nil }

        self.subscription = subscription
        self.channels = subscribedChannels
        self.symbols = Symbols(
            createSamples: createSamples, createSamplesDelta: createDelta, group: group, subgroup: subgroup,
            name: name, unit: unit, format: format, simpleValue: simpleValue,
            stateCount: stateCount, stateName: stateName, stateResidency: stateResidency
        )
    }

    /// Channels accumulated since the previous call, with the elapsed interval.
    /// The first call primes the sampler and returns `nil`.
    public func sample() -> (channels: [IOReportChannel], interval: TimeInterval)? {
        guard let current = symbols.createSamples(subscription, channels, nil)?.takeRetainedValue() else { return nil }
        let now = Date()
        defer { previous = (current, now) }
        guard let previous,
              let delta = symbols.createSamplesDelta(previous.sample, current, nil)?.takeRetainedValue(),
              let list = (delta as NSDictionary)["IOReportChannels"] as? [NSDictionary] else { return nil }
        return (list.map { parse($0 as CFDictionary) }, now.timeIntervalSince(previous.date))
    }

    private func parse(_ channel: CFDictionary) -> IOReportChannel {
        func string(_ function: ChannelString) -> String? { function(channel)?.takeUnretainedValue() as String? }
        // Formats from IOReportTypes.h: 1 = simple, 2 = state.
        let value: IOReportChannel.Value = switch symbols.format(channel) {
        case 1:
            .simple(symbols.simpleValue(channel, 0))
        case 2:
            .states((0..<symbols.stateCount(channel)).map { index in
                IOReportChannel.State(
                    name: (symbols.stateName(channel, index)?.takeUnretainedValue() as String?) ?? "",
                    residency: symbols.stateResidency(channel, index)
                )
            })
        default:
            .unsupported
        }
        return IOReportChannel(
            group: string(symbols.group) ?? "",
            subgroup: string(symbols.subgroup) ?? "",
            name: string(symbols.name) ?? "",
            unit: string(symbols.unit)?.trimmingCharacters(in: .whitespaces),
            value: value
        )
    }
}
