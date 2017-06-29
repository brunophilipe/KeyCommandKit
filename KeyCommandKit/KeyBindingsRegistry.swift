//
//  KeyBindingsRegistry.swift
//  KeyCommandKit
//
//  Created by Bruno Philipe on 25/6/17.
//  Copyright © 2017 Bruno Philipe. All rights reserved.
//

import Foundation

let kKeyCommandKitError = "com.brunophilipe.KeyCommandKit.Error"

public let UIKeyInputBackspace: String = "\u{8}"
public let UIKeyInputTab: String = "\u{9}"
public let UIKeyInputReturn: String = "\u{A}"

public class KeyBindingsRegistry
{
	typealias KeyBindingsProviderHash = Int

	private var keyBindings: [KeyBindingsProviderHash : [String : KeyBinding]] = [:]
	private var providers: [KeyBindingsProviderHash: KeyBindingsProvider.Type] = [:]

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
			providers[provider.providerHash] = provider
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

internal extension KeyBindingsRegistry
{
	var providersCount: Int
	{
		return keyBindings.count
	}

	func bindingsCountForProvider(withIndex index: Int) -> Int
	{
		let keys = keyBindings.keys
		let index = keys.index(keys.startIndex, offsetBy: index)
		let providerKey = keys[index]

		return keyBindings[providerKey]?.count ?? 0
	}

	func binding(withIndex bindingIndex: Int, forProviderWithIndex providerIndex: Int) -> KeyBinding?
	{
		let keys = keyBindings.keys
		let index = keys.index(keys.startIndex, offsetBy: providerIndex)
		let providerKey = keys[index]

		if let bindings = keyBindings[providerKey]
		{
			let bindingsKeys = bindings.keys
			let index = bindingsKeys.index(bindingsKeys.startIndex, offsetBy: bindingIndex)
			let bindingKey = bindingsKeys[index]

			return bindings[bindingKey]
		}
		else
		{
			return nil
		}
	}

	func nameForProvider(withIndex index: Int) -> String?
	{
		let keys = providers.keys
		let index = keys.index(keys.startIndex, offsetBy: index)
		let providerKey = keys[index]

		return providers[providerKey]?.providerName
	}
}
