//
//  KeyCommandBindingsViewController.swift
//  KeyCommandKit - Provides customizable key commands to iOS Apps
//
//  Created by Bruno Philipe on 25/6/17.
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

import UIKit

@IBDesignable
open class KeyBindingsViewController: UITableViewController
{
	private lazy var registry = KeyBindingsRegistry.default

	override open func viewDidLoad()
	{
        super.viewDidLoad()

        tableView.register(UINib(nibName: "KeyBindingCell", bundle: Bundle(for: KeyBindingsViewController.self)),
                           forCellReuseIdentifier: "KeyBindingCell")

		navigationItem.title = "Key Bindings"
    }

	override open func didReceiveMemoryWarning()
	{
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	/// Place for subclasses to customize the editor controller. Default implementation does nothing.
	open func setupEditorController(_ editorController: KeyBindingEditorViewController)
	{}

	private var keyCommandsCache: ([UIKeyCommand], [UIKeyCommand : IndexPath])? = nil

	open override var keyCommands: [UIKeyCommand]?
	{
		if let keyCommands = keyCommandsCache?.0
		{
			return keyCommands
		}

		let keyBindings = registry.allEnabledBindings()
		let selector = #selector(KeyBindingsViewController.showKeyBinding(_:))
		let keyCommandsMap = keyBindings.remappingKeys { $0.make(withAction: selector, hidden: true) }
		let keyCommands = Array(keyCommandsMap.keys)

		keyCommandsCache = (keyCommands, keyCommandsMap)

		return keyCommands
	}

	@objc private func showKeyBinding(_ keyCommand: UIKeyCommand?)
	{
		guard
			let keyCommand = keyCommand,
			let cache = keyCommandsCache,
			let tableView = self.tableView,
			let indexPath = cache.1[keyCommand]
		else
		{
			return
		}

		tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)

		DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
			tableView.deselectRow(at: indexPath, animated: true)
		}
	}

    // MARK: - Table view data source

	override open func numberOfSections(in tableView: UITableView) -> Int
	{
        return registry.providersCount
    }

	override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
        return registry.bindingsCountForProvider(withIndex: section)
    }

	override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		return registry.nameForProvider(withIndex: section)
	}

	override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
        let cell = tableView.dequeueReusableCell(withIdentifier: "KeyBindingCell", for: indexPath)

		guard
			let keyBindingCell = cell as? KeyBindingCell,
			let original = registry.binding(withIndex: indexPath.row, forProviderWithIndex: indexPath.section)
		else
		{
			return cell
		}

		// binding will be equivallent to original if there's no customization
		let binding = registry.customization(forKeyBinding: original, inProviderWithIndex: indexPath.section)

		keyBindingCell.titleLabel.text = binding.name

		if binding.isUnassigned
		{
			keyBindingCell.keyBindingLabel.isHidden = true
		}
		else
		{
			keyBindingCell.keyBindingLabel.keyBinding = binding
			keyBindingCell.keyBindingLabel.isHidden = false
		}

		if cell.selectionStyle == .none
		{
			cell.backgroundView?.removeFromSuperview()
		}
		else
		{
			cell.selectedBackgroundView = UIView()
			cell.selectedBackgroundView?.backgroundColor = tableView.tintColor
		}

        return cell
    }

	override open func tableView(_ aTableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		let providerIndex = indexPath.section
		let registry = self.registry

		// binding will be equivalent to original if there's no customization
		guard let original = registry.binding(withIndex: indexPath.row, forProviderWithIndex: providerIndex) else
		{
			return
		}

		let binding = registry.customization(forKeyBinding: original, inProviderWithIndex: indexPath.section)

		let editorViewController = KeyBindingEditorViewController(binding: binding)
		editorViewController.view.tintColor = view.tintColor

		let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
										   target: editorViewController,
										   action: #selector(KeyBindingEditorViewController.cancel))
		editorViewController.navigationItem.leftBarButtonItem = cancelButton

		let navController = UINavigationController(rootViewController: editorViewController)
		navController.navigationBar.barStyle = .default
		navController.navigationBar.tintColor = view.tintColor
		navController.modalPresentationStyle = .popover
		navController.preferredContentSize = editorViewController.preferredContentSize

		present(navController, animated: true, completion: nil)

		// Get source view to place the popover
		if let view = (tableView.cellForRow(at: indexPath) as? KeyBindingCell)?.keyBindingLabel,
		   let popoverController = navController.popoverPresentationController
		{
			popoverController.backgroundColor = tableView.backgroundColor?.withAlphaComponent(0.9)
			popoverController.permittedArrowDirections = .right
			popoverController.sourceView = view
			popoverController.sourceRect = CGRect(x: 0, y: view.bounds.midY, width: view.bounds.width, height: 0)
		}

		editorViewController.completion =
			{
				editorResult in

				self.tableView.deselectRow(at: indexPath, animated: true)

				var indexPathsToReload: [IndexPath] = [indexPath]

				guard let editorResult = editorResult else
				{
					// Nil result means the user canceled the editor
					return
				}

				switch editorResult
				{
				case .customize(let newBinding):
					registry.registerCustomization(input: newBinding.input,
												   modifiers: newBinding.modifiers,
												   forKeyBinding: binding,
												   inProviderWithIndex: providerIndex)

				case .unsassignAndCustomize(let unassignedBinding, let customizedBinding):
					registry.customizeAsUnassigned(forKeyBinding: unassignedBinding.binding,
												   inProviderWithIndex: unassignedBinding.providerIndex)

					registry.registerCustomization(input: customizedBinding.input,
												   modifiers: customizedBinding.modifiers,
												   forKeyBinding: binding,
												   inProviderWithIndex: providerIndex)

					if let unassignedIndexPath = registry.indexPath(for: unassignedBinding.binding)
					{
						indexPathsToReload.append(unassignedIndexPath)
					}

				case .revert:
					registry.removeCustomization(forKeyBinding: binding,
												 inProviderWithIndex: providerIndex)

				case .revertAndUnassign(let unassignedBinding):
					registry.customizeAsUnassigned(forKeyBinding: unassignedBinding.binding,
												   inProviderWithIndex: unassignedBinding.providerIndex)

					registry.removeCustomization(forKeyBinding: binding,
												 inProviderWithIndex: providerIndex)

					if let unassignedIndexPath = registry.indexPath(for: unassignedBinding.binding)
					{
						indexPathsToReload.append(unassignedIndexPath)
					}

				case .revertBoth(let conflictedBinding):
					registry.removeCustomization(forKeyBinding: binding,
												 inProviderWithIndex: providerIndex)

					registry.removeCustomization(forKeyBinding: conflictedBinding.binding,
												 inProviderWithIndex: conflictedBinding.providerIndex)

					if let unassignedIndexPath = registry.indexPath(for: conflictedBinding.binding)
					{
						indexPathsToReload.append(unassignedIndexPath)
					}

				case .unassign:
					registry.customizeAsUnassigned(forKeyBinding: binding,
												   inProviderWithIndex: providerIndex)
				}

				self.tableView.reloadRows(at: indexPathsToReload, with: .automatic)
			}

		setupEditorController(editorViewController)
	}
}

public class KeyBindingCell: UITableViewCell
{
	@IBOutlet public var titleLabel: UILabel!
	@IBOutlet public var keyBindingLabel: KeyBindingLabel!
}

extension Dictionary
{
	func remappingKeys<K>(_ keyremapperBlock: (Key) -> K?) -> [K: Value]
	{
		var newDict = [K: Value](minimumCapacity: count)

		forEach
			{
				if let newKey = keyremapperBlock($0)
				{
					newDict[newKey] = $1
				}
			}

		return newDict
	}
}
