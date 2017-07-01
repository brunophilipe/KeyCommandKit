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

        return cell
    }

	override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		if let binding = KeyBindingsRegistry.default.binding(withIndex: indexPath.row, forProviderWithIndex: indexPath.section)
		{
			let editorViewController = KeyBindingEditorViewController(binding: binding)
			editorViewController.tableView.backgroundColor = tableView.backgroundColor
			editorViewController.tableView.separatorColor = tableView.separatorColor
			editorViewController.cellTextColor = cellTextColor
			editorViewController.cellBackgroundColor = cellBackgroundColor

			navigationController?.pushViewController(editorViewController, animated: true)
		}
	}

	override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		return KeyBindingsRegistry.default.nameForProvider(withIndex: section)
	}
}

class KeyBindingEditorViewController: UITableViewController
{
	var cellBackgroundColor: UIColor? = nil
	var cellTextColor: UIColor? = nil

	var binding: KeyBinding

	init(binding: KeyBinding)
	{
		self.binding = binding
		super.init(style: .grouped)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad()
	{
		super.viewDidLoad()

		navigationItem.title = "Customize Binding"
	}

	override public func numberOfSections(in tableView: UITableView) -> Int
	{
		return 3
	}

	override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return 1
	}

	override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell: UITableViewCell

		var detailTextColor: UIColor? = nil
		var normalTextColor: UIColor? = nil

		switch (indexPath.section, indexPath.row)
		{
		case (0, 0):
			cell = UITableViewCell(style: .value2, reuseIdentifier: "binding_title")
			cell.detailTextLabel?.text = binding.name
			cell.textLabel?.text = "Action"

			detailTextColor = cellTextColor
			normalTextColor = navigationController?.navigationBar.tintColor

		default:
			cell = UITableViewCell()
		}

		if let color = self.cellBackgroundColor
		{
			cell.backgroundColor = color
		}

		if let color = detailTextColor
		{
			cell.detailTextLabel?.textColor = color
		}

		if let color = normalTextColor
		{
			cell.textLabel?.textColor = color
		}

		return cell
	}
}
