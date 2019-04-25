//
//  KeyBinding.swift
//  KeyCommandKit - Provides customizable key commands to iOS Apps
//
//  Created by Bruno Philipe on 30/6/17.
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

let UnassignedKeyBindingInput = "Unassigned"

public class KeyBinding
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

	/// Whether this is a customization where the user unassigned the key binding, effectively deactivating it.
	var isUnassigned: Bool
	{
		return input == UnassignedKeyBindingInput
	}

	/// Makes a UIKeyCommand instance by attaching an action to the receiver binding. If the receiver binding was
	/// customized to "Unassigned" by the user, this method returns `nil`.
	public func make(withAction action: Selector) -> UIKeyCommand?
	{
		return make(withAction: action, hidden: false)
	}

	/// Makes a UIKeyCommand instance by attaching an action to the receiver binding. If the receiver binding was
	/// customized to "Unassigned" by the user, this method returns `nil`. If `hidden` is `true`, makes the key command
	/// as undiscoverable, even if it was originally registered as discoverable. This is used in the key bindings
	/// editor.
	internal func make(withAction action: Selector, hidden: Bool) -> UIKeyCommand?
	{
		if isUnassigned
		{
			return nil
		}

		if isDiscoverable, #available(iOS 9.0, *), !hidden
		{
			return UIKeyCommand(input: input, modifierFlags: modifiers, action: action, discoverabilityTitle: name)
		}
		else
		{
			return UIKeyCommand(input: input, modifierFlags: modifiers, action: action)
		}
	}

	public init(key: String, name: String, input: String, modifiers: UIKeyModifierFlags, isDiscoverable: Bool = true)
	{
		self.key = key
		self.name = name
		self.input = input
		self.modifiers = modifiers
		self.isDiscoverable = isDiscoverable
	}
}

internal class CustomizedKeyBinding: KeyBinding
{
	/// Flag that indicates wether this binding was customized by the user.
	override public var isCustomized: Bool
	{
		return true
	}

	var originalInput: String
	var originalModifiers: UIKeyModifierFlags

	init(key: String, name: String, input: String, modifiers: UIKeyModifierFlags, isDiscoverable: Bool, originalInput: String, originalModifiers: UIKeyModifierFlags)
	{
		self.originalInput = originalInput
		self.originalModifiers = originalModifiers

		super.init(key: key, name: name, input: input, modifiers: modifiers, isDiscoverable: isDiscoverable)
	}

	var originalBinding: KeyBinding
	{
		return KeyBinding(key: key, name: name, input: originalInput, modifiers: originalModifiers, isDiscoverable: isDiscoverable)
	}
}

internal extension KeyBinding
{
	func isEquivalent(toKeyBinding keyBinding: KeyBinding) -> Bool
	{
		return keyBinding.input == self.input && keyBinding.modifiers == self.modifiers
	}

	func isEquivalent(toKeyCommand keyCommand: UIKeyCommand) -> Bool
	{
		return keyCommand.input == self.input && keyCommand.modifierFlags == self.modifiers
	}

	var stringRepresentation: String
	{
		var string = ""

		if modifiers.contains(.control)
		{
			string += "⌃"
		}

		if modifiers.contains(.alternate)
		{
			string += "⌥"
		}

		if modifiers.contains(.shift)
		{
			string += "⇧"
		}

		if modifiers.contains(.command)
		{
			string += "⌘"
		}

		switch input
		{
		case UIKeyCommand.inputLeftArrow:
			string += "←"

		case UIKeyCommand.inputRightArrow:
			string += "→"

		case UIKeyCommand.inputUpArrow:
			string += "↑"

		case UIKeyCommand.inputDownArrow:
			string += "↓"

		case UIKeyCommand.inputEscape:
			string += "⎋"

		case UIKeyCommand.inputBackspace:
			string += "⌫"

		case UIKeyCommand.inputTab:
			string += "⇥"

		case UIKeyCommand.inputReturn:
			string += "↩︎"

		default:
			string += input.uppercased()
		}

		return string
	}

	func customized(input: String, modifiers: UIKeyModifierFlags) -> KeyBinding
	{
		return CustomizedKeyBinding(key: key, name: name, input: input, modifiers: modifiers,
									isDiscoverable: isDiscoverable, originalInput: self.input,
									originalModifiers: self.modifiers)
	}
}

public extension Dictionary where Key == String, Value == KeyBinding
{
	/// Makes UIKeyCommand objects by attaching key bindings to actions by matching their respective `key`s.
	/// If a key binding was customized to "Unassigned" by the user, then this routine skips it.
	func make(withActionsForKeys tuples: [(key: String, action: Selector)]) -> [UIKeyCommand]
	{
		var keyCommands = [UIKeyCommand]()

		for (key, action) in tuples
		{
			if let binding = self[key], let keyCommand = binding.make(withAction: action)
			{
				keyCommands.append(keyCommand)
			}
		}

		return keyCommands
	}
}

extension KeyBinding: Hashable
{
	public static func == (lhs: KeyBinding, rhs: KeyBinding) -> Bool
	{
		return lhs.hashValue == rhs.hashValue
	}

	public var hashValue: Int
	{
		return "\(key.hashValue)\(input.hashValue)\(modifiers.rawValue)".hashValue
	}
}
