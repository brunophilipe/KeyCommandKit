//
//  KeyBindingsRegistry.swift
//  KeyCommandKit - Provides customizable key commands to iOS Apps
//
//  Created by Bruno Philipe on 25/6/17.
//  Copyright (C) 2017  Bruno Philipe <git@bruno.ph>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import Foundation

let kKeyCommandKitError = "com.brunophilipe.KeyCommandKit.Error"

extension UIKeyCommand
{
	@available(iOS 7.0, *)
	public static let inputBackspace: String = "\u{8}"
	
	@available(iOS 7.0, *)
	public static let inputTab: String = "\u{9}"
	
	@available(iOS 7.0, *)
	public static let inputReturn: String = "\u{D}"
	
	@available(iOS 7.0, *)
	public static let inputDelete: String = "\u{7F}"
}

public class KeyBindingsRegistry
{
	typealias KeyBindingsProviderHash = Int

	private var providersSortOrder: [KeyBindingsProviderHash] = []
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

	/// List of forbidden key commands. Any key commands set here will not be available to the user as a customization.
	public var forbiddenKeyCommands: [UIKeyCommand] = []

	/// Registers an individual key binding.
	///
	/// - Parameter keyBinding: The key binding to register
	/// - Throws: kKeyCommandKitError:1001 If a key binding has already been registered with the same key, but is
	/// that's not equivalent to the parameter key binding.
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
		providersSortOrder.append(provider.providerHash)

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

	/// Looks up and returns a binding registered in a certain provider with the specified key, or throws an exception
	/// if the specified key is not found.
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

	/// Returns all key bindings provided by a particular provider, indexed by the key of each key binding.
	public func bindings(forProvider provider: KeyBindingsProvider.Type = GlobalKeyBindingsProvider.self) -> [String: KeyBinding]
	{
		guard let keyBindings = keyBindings[provider.providerHash] else
		{
			return [:]
		}

		let customizedBindings = keyBindings.values.map({ customization(forKeyBinding: $0, inProvider: provider) })
		return zip(Array(keyBindings.keys), customizedBindings).reduce([String: KeyBinding]())
			{
				var dict = $0
				dict[$1.0] = $1.1
				return dict
			}
	}
}

internal extension KeyBindingsRegistry
{
	/// Load all customizations from the storage file.
	func loadCustomizations()
	{
		customizations = [:]

		if let bindingsFileURL = self.bindingsFileURL,
			let providersDict = NSDictionary(contentsOf: bindingsFileURL) as? [String: [String : [String : AnyObject]]]
		{
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

	/// Write all customizations to the storage file.
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

	/// Returns a key binding with any customizations set by the user for a particular provider, or the unchanged input
	/// key binding if there are no customizations set.
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

	/// Returns the bindings customization file URL.
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

/// This extenstion provides methods to help render the key bindings table view.
internal extension KeyBindingsRegistry
{
	/// Returns the count of registered providers.
	var providersCount: Int
	{
		return keyBindings.count
	}

	/// Returns the unique identifier hash for a given provider.
	func keyForProvider(withIndex providerIndex: Int) -> KeyBindingsProviderHash?
	{
		return providersSortOrder[providerIndex]
	}

	func customizeAsUnassigned(forKeyBinding binding: KeyBinding, inProviderWithIndex index: Int)
	{
		registerCustomization(input: UnassignedKeyBindingInput, modifiers: [],
							  forKeyBinding: binding, inProviderWithIndex: index)
	}

	/// Register a user-customizarion for a key binding.
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

	/// Remove a customization for a key binding, effectively restoring it to the default binding.
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

	/// Looks up if there's a customization for a key binding, and returns it with that customization set, or returns
	/// the same object if there's no customization registered. This is an internal method used to render the bindings
	/// table view, and shouldn't be used for other purposes.
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

	/// Returns the count of key bindings provided by a particular provider. This is an internal method used to render
	/// the bindings table view, and shouldn't be used for other purposes.
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

	/// Returns all bindings enabled in the registry, so the user can press them to jump to its place in the editor
	/// table view controller
	func allEnabledBindings() -> [KeyBinding : IndexPath]
	{
		var allBindings = [KeyBinding : IndexPath]()

		for providerIndex in 0 ..< providersCount
		{
			for bindingIndex in 0 ..< bindingsCountForProvider(withIndex: providerIndex)
			{
				guard let binding = binding(withIndex: bindingIndex, forProviderWithIndex: providerIndex) else
				{
					continue
				}
				
				// The custom binding will be equivalent to the binding if no customization is set.
				let customBinding = customization(forKeyBinding: binding, inProviderWithIndex: providerIndex)

				allBindings[customBinding] = IndexPath(row: bindingIndex, section: providerIndex)
			}
		}

		return allBindings
	}

	/// Returns the n-th binding provided by a given provider. This is an internal method used to render the bindings
	/// table view, and shouldn't be used for other purposes.
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

	/// Returns the human-readable name of a provider.
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

	func indexPath(for lookupBinding: KeyBinding) -> IndexPath?
	{
		for (section, providerHash) in providersSortOrder.enumerated()
		{
			for (row, binding) in keyBindings[providerHash]!.enumerated()
			{
				if binding.key == lookupBinding.key
				{
					return IndexPath(row: row, section: section)
				}
			}
		}
		return nil
	}

	/// Returns the first installed binding (including customizations) that is equivalent to the provided binding, if any.
	func firstBinding(equivalentTo lookupCommand: UIKeyCommand) -> BindingConflict?
	{
		return firstBinding(equivalentTo: (lookupCommand.input!, lookupCommand.modifierFlags))
	}

	/// Returns the first installed binding (including customizations) that is equivalent to the provided binding, if any.
	func firstBinding(equivalentTo lookupBinding: KeyBinding) -> BindingConflict?
	{
		return firstBinding(equivalentTo: (lookupBinding.input, lookupBinding.modifiers), notMatchingKey: lookupBinding.key)
	}

	/// Returns the first installed binding (including customizations) that is equivalent to the provided binding, if any.
	func firstBinding(equivalentTo lookup: (input: String, modifiers: UIKeyModifierFlags), notMatchingKey key: String? = nil) -> BindingConflict?
	{
		for (providerHash, bindings) in keyBindings
		{
			let provider = providers[providerHash]!
			if let equivalentBinding = bindings.first(where:
				{
					_, installedBinding in
					let customizedBinding = self.customization(forKeyBinding: installedBinding, inProvider: provider)

					return customizedBinding.input.lowercased() == lookup.input.lowercased()
							&& customizedBinding.modifiers == lookup.modifiers
							&& (key == nil || customizedBinding.key != key)
				})
			{
				let providerIndex = providersSortOrder.index(of: providerHash)!
				return BindingConflict(providerHash: providerHash,
									   providerIndex: providerIndex,
									   key: equivalentBinding.key,
									   binding: equivalentBinding.value)
			}
		}

		return nil
	}

	struct BindingConflict
	{
		let providerHash: Int
		let providerIndex: Int
		let key: String
		let binding: KeyBinding
	}
}
