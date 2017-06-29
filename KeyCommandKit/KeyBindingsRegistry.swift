//
//  KeyBindingsRegistry.swift
//  KeyCommandKit
//
//  Created by Bruno Philipe on 25/6/17.
//  Copyright © 2017 Bruno Philipe. All rights reserved.
//

import Foundation

let kKeyCommandKitError = "com.brunophilipe.KeyCommandKit.Error"

public class KeyBindingsRegistry
{
	typealias KeyBindingsProviderHash = Int

	private var keyBindings: [KeyBindingsProviderHash : [String : KeyBinding]] = [:]

	public static let `default`: KeyBindingsRegistry = KeyBindingsRegistry()

	/// Registers an individual key binding.
	///
	/// - Parameter keyBinding: The key binding to register
	/// - Throws: kKeyCommandKitError:1001 If a key binding has already been registered with the same key, but is that's not equivalent to
	/// the parameter key binding.
	public func register(keyBinding: KeyBinding) throws
	{
		try register(keyBinding: keyBinding, forProvider: GlobalKeyBindingsProvider.self)
	}

	/// Convenience method to register multiple key bindings. See: `register(keyBinding:)`.
	public func register(keyBindings: [KeyBinding]) throws
	{
		for keyBinding in keyBindings
		{
			try register(keyBinding: keyBinding)
		}
	}

	/// Registers a static provider of key bindings.
	///
	/// Notice this calls the `provideKeyBindings()` method, which is *static*.
	public func register(provider: KeyBindingsProvider.Type) throws
	{
		for keyBinding in provider.provideKeyBindings()
		{
			try register(keyBinding: keyBinding, forProvider: provider)
		}
	}

	/// Registers a binding for a specific provider.
	///
	/// Notice this calls the `provideKeyBindings()` method, which is *static*.
	public func register(keyBinding: KeyBinding, forProvider provider: KeyBindingsProvider.Type) throws
	{
		var keyBindings = self.keyBindings[provider.providerHash] ?? [String : KeyBinding]()

		if keyBindings[keyBinding.key] == nil
		{
			keyBindings[keyBinding.key] = keyBinding
		}
		else if !(keyBindings[keyBinding.key]!.isEquivalent(toKeyBinding: keyBinding))
		{
			throw NSError(domain: kKeyCommandKitError,
			              code: 1001,
			              userInfo: [NSLocalizedDescriptionKey: "Consistency error: Attempted to register different key binding with same identifier: \(keyBinding.key)"])
		}

		self.keyBindings[provider.providerHash] = keyBindings
	}

	public func binding(withKey key: String, forProvider provider: KeyBindingsProvider.Type = GlobalKeyBindingsProvider.self) throws -> KeyBinding
	{
		if let binding = self.keyBindings[provider.providerHash]?[key]
		{
			return binding
		}
		else
		{
			throw NSError(domain: kKeyCommandKitError,
			              code: 1002,
			              userInfo: [NSLocalizedDescriptionKey: "No key binding with key \(key) found for provider \(provider.description)"])
		}
	}

	public func bindings(forProvider provider: KeyBindingsProvider.Type = GlobalKeyBindingsProvider.self) -> [KeyBinding]
	{
		if let bindings = keyBindings[provider.providerHash]
		{
			return bindings.map({$0.value})
		}
		else
		{
			return []
		}
	}
}

public extension Array where Element == KeyBinding
{
	public func make(withActionsForKeys actions: [String : Selector]) -> [UIKeyCommand]
	{
		var keyCommands = [UIKeyCommand]()

		for binding in self
		{
			if let action = actions[binding.key]
			{
				keyCommands.append(binding.make(withAction: action))
			}
		}

		return keyCommands
	}
}

public protocol KeyBindingsProvider: NSObjectProtocol
{
	static func provideKeyBindings() -> [KeyBinding]
}

internal extension KeyBindingsProvider
{
	internal static var description: String
	{
		return NSStringFromClass(Self.self)
	}

	internal static var providerHash: Int
	{
		return NSStringFromClass(Self.self).hash
	}
}

public class GlobalKeyBindingsProvider: NSObject, KeyBindingsProvider
{
	public static func provideKeyBindings() -> [KeyBinding] {
		return []
	}
}

public struct KeyBinding
{
	/// An internal identifier. Must be unique, and is used to query key bindings. It is never shown to the user.
	public let key: String

	/// A user-friendly description. It is shown in the system discoverability UI if the `isDiscoverable` property is true.
	public let name: String

	/// Whether this binding should be shown in the system discoverability UI.
	public let isDiscoverable: Bool

	/// The default input for this binding. Can be customized by the user, but the default will always be stored.
	public let input: String

	/// The default modifiers for this binding. Can be customized by the user, but the default will always be stored.
	public let modifiers: UIKeyModifierFlags

	/// Flag that indicates wether this binding was customized by the user.
	public var isCustomized: Bool
	{
		return false
	}

	public func make(withAction action: Selector) -> UIKeyCommand
	{
		if isDiscoverable, #available(iOS 9.0, *)
		{
			return UIKeyCommand(input: input, modifierFlags: modifiers, action: action, discoverabilityTitle: name)
		}
		else
		{
			return UIKeyCommand(input: input, modifierFlags: modifiers, action: action)
		}
	}

	public init(key: String, name: String, input: String, modifiers: UIKeyModifierFlags, isDiscoverable: Bool)
	{
		self.key = key
		self.name = name
		self.input = input
		self.modifiers = modifiers
		self.isDiscoverable = isDiscoverable
	}

	internal func isEquivalent(toKeyBinding keyBinding: KeyBinding) -> Bool
	{
		return keyBinding.input == self.input && keyBinding.modifiers == self.modifiers
	}
}
