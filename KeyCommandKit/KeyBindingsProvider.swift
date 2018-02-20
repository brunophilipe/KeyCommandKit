//
//  KeyBindingsProvider.swift
//  KeyCommandKit - Provides customizable key commands to iOS Apps
//
//  Created by Bruno Philipe on 30/6/17.
//  Copyright (C) 2017  Bruno Philipe <git@bruno.ph>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
