//
//  KeyBindingsProvider.swift
//  KeyCommandKit
//
//  Created by Bruno Philipe on 30/6/17.
//  Copyright © 2017 Bruno Philipe. All rights reserved.
//

import Foundation

public protocol KeyBindingsProvider: NSObjectProtocol
{
	static func provideKeyBindings() -> [KeyBinding]

	static var providerName: String { get }
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

	public static var providerName: String
	{
		return "General"
	}
}
