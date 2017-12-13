//
//  KeyCommandBindingsViewController.swift
//  KeyCommandKit
//
//  Created by Bruno Philipe on 25/6/17.
//  Copyright © 2017 Bruno Philipe. All rights reserved.
//

import UIKit

@IBDesignable
open class KeyBindingsViewController: UITableViewController
{
	@IBInspectable var cellBackgroundColor: UIColor? = nil
	@IBInspectable var cellTextColor: UIColor? = nil

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

    // MARK: - Table view data source

	override open func numberOfSections(in tableView: UITableView) -> Int
	{
        return KeyBindingsRegistry.default.providersCount
    }

	override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
        return KeyBindingsRegistry.default.bindingsCountForProvider(withIndex: section)
    }

	override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
        let cell = tableView.dequeueReusableCell(withIdentifier: "KeyBindingCell", for: indexPath)

		if let keyBindingCell = cell as? KeyBindingCell,
			let original = KeyBindingsRegistry.default.binding(withIndex: indexPath.row, forProviderWithIndex: indexPath.section)
		{
			// binding will be equivallent to original if there's no customization
			let binding = KeyBindingsRegistry.default.customization(forKeyBinding: original, inProviderWithIndex: indexPath.section)

			keyBindingCell.titleLabel.text = binding.name
			keyBindingCell.keyBindingLabel.keyBinding = binding
		}

		if let color = self.cellBackgroundColor
		{
			cell.backgroundColor = color
		}

		if let keyBindingCell = cell as? KeyBindingCell, let color = self.cellTextColor
		{
			keyBindingCell.titleLabel.textColor = color
		}

		cell.selectedBackgroundView = UIView()
		cell.selectedBackgroundView?.backgroundColor = view.tintColor

        return cell
    }

	override open func tableView(_ aTableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		let providerIndex = indexPath.section

		if let original = KeyBindingsRegistry.default.binding(withIndex: indexPath.row, forProviderWithIndex: providerIndex)
		{
			// binding will be equivallent to original if there's no customization
			let binding = KeyBindingsRegistry.default.customization(forKeyBinding: original, inProviderWithIndex: indexPath.section)

			let editorViewController = KeyBindingEditorViewController(binding: binding)
			editorViewController.cellTextColor = cellTextColor
			editorViewController.cellBackgroundColor = cellBackgroundColor

			if UIDevice.current.userInterfaceIdiom == .pad
			{
				let navController = UINavigationController(rootViewController: editorViewController)
				navController.navigationBar.barStyle = .default
				navController.navigationBar.tintColor = view.tintColor
				navController.modalPresentationStyle = .popover
				navController.preferredContentSize = editorViewController.preferredContentSize
				editorViewController.view.tintColor = view.tintColor

				let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
				                                   target: editorViewController,
				                                   action: #selector(KeyBindingEditorViewController.cancel))

				editorViewController.navigationItem.leftBarButtonItem = cancelButton

				editorViewController.completion =
					{
						newBinding in

						self.tableView.deselectRow(at: indexPath, animated: true)

						if let newBinding = newBinding
						{
							KeyBindingsRegistry.default.registerCustomization(input: newBinding.input,
							                                                  modifiers: newBinding.modifiers,
							                                                  forKeyBinding: binding,
							                                                  inProviderWithIndex: providerIndex)
						}
						else
						{
							KeyBindingsRegistry.default.removeCustomization(forKeyBinding: binding,
							                                                inProviderWithIndex: providerIndex)
						}

						self.tableView.reloadRows(at: [indexPath], with: .automatic)
					}

				present(navController, animated: true, completion: nil)

				if let view = (tableView.cellForRow(at: indexPath) as? KeyBindingCell)?.keyBindingLabel,
				   let popoverController = navController.popoverPresentationController
				{
					popoverController.backgroundColor = tableView.backgroundColor?.withAlphaComponent(0.9)
					popoverController.permittedArrowDirections = .right
					popoverController.sourceView = view
					popoverController.sourceRect = CGRect(x: 0, y: view.bounds.midY, width: view.bounds.width, height: 0)
				}
			}
			else
			{
				navigationController?.pushViewController(editorViewController, animated: true)
			}
		}
	}

	override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		return KeyBindingsRegistry.default.nameForProvider(withIndex: section)
	}
}

class KeyBindingCell: UITableViewCell
{
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var keyBindingLabel: KeyBindingLabel!
}
