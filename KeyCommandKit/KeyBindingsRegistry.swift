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
public let UIKeyInputReturn: String = "\u{D}"

public class KeyBindingsRegistry
{
	typealias KeyBindingsProviderHash = Int

	private var keyBindings: [KeyBindingsProviderHash : [String : KeyBinding]] = [:]
	private var providers: [KeyBindingsProviderHash: KeyBindingsProvider.Type] = [:]
	private var customizations: [KeyBindingsProviderHash: [String: (input: String, modifiers: UIKeyModifierFlags)]]? = nil

	public var applicationSupportName: String? = nil
	{
		didSet
		{
			loadCustomizations()
		}
	}

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

	public func binding(withKey key: String,
	                    forProvider provider: KeyBindingsProvider.Type = GlobalKeyBindingsProvider.self) throws -> KeyBinding
	{
		if let binding = self.keyBindings[provider.providerHash]?[key]
		{
			return customization(forKeyBinding: binding, inProvider: provider)
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
			return bindings.map({customization(forKeyBinding: $0.value, inProvider: provider)})
		}
		else
		{
			return []
		}
	}
}

internal extension KeyBindingsRegistry
{
	func loadCustomizations()
	{
		if let bindingsFileURL = self.bindingsFileURL,
			let providersDict = NSDictionary(contentsOf: bindingsFileURL) as? [String: [String : [String : AnyObject]]]
		{
			customizations = [:]

			for (providerHash, bindingsArray) in providersDict
			{
				guard let providerHashInt = Int(providerHash) else
				{
					continue
				}

				var bindingTuples = [String : (input: String, modifiers: UIKeyModifierFlags)]()
				for (bindingKey, bindingValues) in bindingsArray
				{
					if let input = bindingValues["input"] as? String, let modifiers = bindingValues["modifiers"] as? Int
					{
						bindingTuples[bindingKey] = (input: input, modifiers: UIKeyModifierFlags(rawValue: modifiers))
					}
				}

				customizations?[providerHashInt] = bindingTuples
			}
		}
	}

	func writeCustomizations()
	{
		if let bindingsFileURL = self.bindingsFileURL, let customizations = self.customizations
		{
			var providersDict = [String: [String : [String : AnyObject]]]()
			for (providerHash, bindingTuples) in customizations
			{
				var bindingsArray = [String : [String : AnyObject]]()
				for bindingTuple in bindingTuples
				{
					bindingsArray[bindingTuple.key] = ["input": bindingTuple.value.input as AnyObject,
					                                   "modifiers": bindingTuple.value.modifiers.rawValue as AnyObject]
				}

				providersDict["\(providerHash)"] = bindingsArray
			}

			(providersDict as NSDictionary).write(to: bindingsFileURL, atomically: true)
		}
	}

	func customization(forKeyBinding binding: KeyBinding,
	                   inProvider provider: KeyBindingsProvider.Type = GlobalKeyBindingsProvider.self) -> KeyBinding
	{
		if let providerCustomizations = self.customizations?[provider.providerHash],
			let customization = providerCustomizations[binding.key]
		{
			return binding.customized(input: customization.input, modifiers: customization.modifiers)
		}
		else
		{
			return binding
		}
	}

	var bindingsFileURL: URL?
	{
		if let applicationName = self.applicationSupportName,
		   let appSupportDir = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
		                                                    appropriateFor: nil, create: true)
		{
			let appDir = appSupportDir.appendingPathComponent(applicationName)

			if !FileManager.default.fileExists(atPath: appDir.path)
			{
				do
				{
					try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true, attributes: nil)
				}
				catch let error
				{
					NSLog("Could not create directory for key bindings: \(error)")
				}
			}

			return appDir.appendingPathComponent("KeyBindings").appendingPathExtension("plist")
		}

		return nil
	}
}

internal extension KeyBindingsRegistry
{
	var providersCount: Int
	{
		return keyBindings.count
	}

	func keyForProvider(withIndex providerIndex: Int) -> KeyBindingsProviderHash?
	{
		let keys = keyBindings.keys
		let index = keys.index(keys.startIndex, offsetBy: providerIndex)
		return keys[index]
	}

	func registerCustomization(input: String, modifiers: UIKeyModifierFlags,
	                           forKeyBinding binding: KeyBinding,
	                           inProviderWithIndex providerIndex: Int)
	{
		var customizations = self.customizations ?? [:]

		if let providerKey = keyForProvider(withIndex: providerIndex)
		{
			if customizations[providerKey] == nil
			{
				customizations[providerKey] = [:]
			}

			customizations[providerKey]?[binding.key] = (input: input, modifiers: modifiers)

			self.customizations = customizations

			writeCustomizations()
		}
	}

	func removeCustomization(forKeyBinding binding: KeyBinding, inProviderWithIndex providerIndex: Int)
	{
		var customizations = self.customizations ?? [:]

		if let providerKey = keyForProvider(withIndex: providerIndex)
		{
			if customizations[providerKey] == nil
			{
				// No customization registered!
				return
			}

			customizations[providerKey]?.removeValue(forKey: binding.key)

			self.customizations = customizations

			writeCustomizations()
		}
	}

	func customization(forKeyBinding binding: KeyBinding, inProviderWithIndex providerIndex: Int) -> KeyBinding
	{
		if let providerKey = keyForProvider(withIndex: providerIndex),
			let customization = self.customizations?[providerKey]?[binding.key]
		{
			return binding.customized(input: customization.input, modifiers: customization.modifiers)
		}
		else
		{
			return binding
		}
	}

	func bindingsCountForProvider(withIndex providerIndex: Int) -> Int
	{
		if let providerKey = keyForProvider(withIndex: providerIndex)
		{
			return keyBindings[providerKey]?.count ?? 0
		}
		else
		{
			return 0
		}
	}

	func binding(withIndex bindingIndex: Int, forProviderWithIndex providerIndex: Int) -> KeyBinding?
	{
		if let providerKey = keyForProvider(withIndex: providerIndex), let bindings = keyBindings[providerKey]
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

	func nameForProvider(withIndex providerIndex: Int) -> String?
	{
		if let providerKey = keyForProvider(withIndex: providerIndex)
		{
			return providers[providerKey]?.providerName
		}
		else
		{
			return nil
		}
	}
}
