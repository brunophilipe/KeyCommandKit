//
//  KeyBindingsProvider.swift
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
