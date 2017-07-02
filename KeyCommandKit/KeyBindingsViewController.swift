//
//  KeyCommandBindingsViewController.swift
//  KeyCommandKit
//
//  Created by Bruno Philipe on 25/6/17.
//  Copyright © 2017 Bruno Philipe. All rights reserved.
//

import UIKit

@IBDesignable
public class KeyBindingsViewController: UITableViewController
{
	@IBInspectable var cellBackgroundColor: UIColor? = nil
	@IBInspectable var cellTextColor: UIColor? = nil

    override public func viewDidLoad()
	{
        super.viewDidLoad()

        tableView.register(UINib(nibName: "KeyBindingCell", bundle: Bundle(for: KeyBindingsViewController.self)),
                           forCellReuseIdentifier: "KeyBindingCell")

		navigationItem.title = "Key Bindings"
    }

    override public func didReceiveMemoryWarning()
	{
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override public func numberOfSections(in tableView: UITableView) -> Int
	{
        return KeyBindingsRegistry.default.providersCount
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
        return KeyBindingsRegistry.default.bindingsCountForProvider(withIndex: section)
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
        let cell = tableView.dequeueReusableCell(withIdentifier: "KeyBindingCell", for: indexPath)

		if let binding = KeyBindingsRegistry.default.binding(withIndex: indexPath.row, forProviderWithIndex: indexPath.section)
		{
			cell.textLabel?.text = binding.name
			cell.detailTextLabel?.text = binding.stringRepresentation
		}

		if let color = self.cellBackgroundColor
		{
			cell.backgroundColor = color
		}

		if let color = self.cellTextColor
		{
			cell.textLabel?.textColor = color
			cell.detailTextLabel?.textColor = color
		}

		cell.selectedBackgroundView = UIView()
		cell.selectedBackgroundView?.backgroundColor = view.tintColor

        return cell
    }

	override public func tableView(_ aTableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		if let binding = KeyBindingsRegistry.default.binding(withIndex: indexPath.row, forProviderWithIndex: indexPath.section)
		{
			let editorViewController = KeyBindingEditorViewController(binding: binding)
			editorViewController.cellTextColor = cellTextColor
			editorViewController.cellBackgroundColor = cellBackgroundColor

			if UIDevice.current.userInterfaceIdiom == .pad
			{
				let navController = UINavigationController(rootViewController: editorViewController)
				navController.navigationBar.barStyle = .blackOpaque
				navController.navigationBar.tintColor = view.tintColor
				navController.modalPresentationStyle = .popover
				navController.preferredContentSize = editorViewController.preferredContentSize
				editorViewController.view.tintColor = view.tintColor
				editorViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
				                                                                        target: editorViewController,
				                                                                        action: #selector(KeyBindingEditorViewController.cancel))

				editorViewController.completion =
					{
						self.tableView.deselectRow(at: indexPath, animated: true)
					}

				present(navController, animated: true, completion: nil)

				let cell = tableView(aTableView, cellForRowAt: indexPath)
				if let view = cell.detailTextLabel, let popoverController = navController.popoverPresentationController
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

	override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		return KeyBindingsRegistry.default.nameForProvider(withIndex: section)
	}
}
