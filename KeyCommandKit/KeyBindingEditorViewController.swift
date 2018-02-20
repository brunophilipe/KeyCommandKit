//
//  KeyBindingEditorViewController.swift
//  KeyCommandKit - Provides customizable key commands to iOS Apps
//
//  Created by Bruno Philipe on 3/7/17.
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

public class KeyBindingEditorViewController: UIViewController
{
	var binding: KeyBinding

	var result: EditorResult? = nil

	var completion: ((EditorResult?) -> Void)? = nil

	var editorView: KeyBindingEditorView?
	{
		return view as? KeyBindingEditorView
	}

	init(binding: KeyBinding)
	{
		self.binding = binding
		super.init(nibName: "KeyBindingEditorView", bundle: Bundle(for: KeyBindingEditorViewController.self))

		self.preferredContentSize = CGSize(width: 275.0, height: 200.0)
	}

	required public init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	override public func viewDidLoad()
	{
		super.viewDidLoad()

		editorView?.viewController = self
		updateLabels()

		navigationItem.title = ""

		if binding is CustomizedKeyBinding
		{
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Revert",
			                                                    style: .plain,
			                                                    target: self,
			                                                    action: #selector(KeyBindingEditorViewController.revert))
		}
	}

	override public func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		let keyBindingControl = KeyBindingInputControl(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
		keyBindingControl.newBindingAction =
			{
				keyCommand in

				let binding = KeyBinding(key: "", name: "",
				                         input: keyCommand.input!, modifiers: keyCommand.modifierFlags,
				                         isDiscoverable: false)

				self.result = .customize(self.binding.customized(input: binding.input, modifiers: binding.modifiers))

				self.updateLabels()
			}

		view.addSubview(keyBindingControl)

		keyBindingControl.becomeFirstResponder()
	}

	override public func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)

		DispatchQueue.main.async
			{
				self.completion?(self.result)
			}
	}

	public func setInstructions(_ text: String)
	{
		instructionsLabel.text = text
	}

	public var instructionsLabel: UILabel
	{
		return editorView!.instructionsLabel
	}

	public var unassignedLabel: UILabel
	{
		return editorView!.unassignedLabel
	}

	@objc func save()
	{
		dismiss(animated: true)
	}

	@objc func revert()
	{
		self.result = .revert

		dismiss(animated: true)
	}

	@objc func cancel()
	{
		self.result = nil

		dismiss(animated: true)
	}

	@objc func unassign()
	{
		self.result = .unassign

		dismiss(animated: true)
	}

	enum EditorResult
	{
		case customize(KeyBinding)
		case revert
		case unassign
	}

	// Private

	private func updateLabels()
	{
		guard let editorView = self.editorView else
		{
			// If there's no editor view, there are no labels to update!
			return
		}

		let binding: KeyBinding

		// If there is a customized binding set, we read from there
		if case .some(.customize(let newBinding)) = result
		{
			binding = newBinding
		}
		else
		{
			binding = self.binding
		}

		let isUnassignedBinding = binding.isUnassigned
		editorView.unassignedLabel.isHidden = !isUnassignedBinding
		editorView.keyBindingDisplayLabel.isHidden = isUnassignedBinding
		editorView.unassignButton.isEnabled = !isUnassignedBinding
		editorView.saveButton.isEnabled = result != nil

		if !isUnassignedBinding
		{
			editorView.keyBindingDisplayLabel.keyBinding = binding
		}
	}
}

extension KeyBindingEditorViewController: UITextFieldDelegate
{
	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
	{
		return false
	}
}

class KeyBindingInputControl: UIControl
{
	private var _keyCommands: [UIKeyCommand]!

	var newBindingAction: ((UIKeyCommand) -> Void)? = nil

	override init(frame: CGRect)
	{
		super.init(frame: frame)

		makeKeyCommands()
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	private func makeKeyCommands()
	{
		let special = UIKeyInputBackspace + UIKeyInputTab + UIKeyInputReturn + UIKeyInputDelete
		let characters = "\(special)abcdefghijklmnopqrstuvwxyz!\"#$%&'()*+,-./0123456789:;<=>º?@[\\]^_`´{|}~"

		var keyCommands = [UIKeyCommand]()

		var inputs = characters.map({ String($0) })

		inputs.append(contentsOf: [UIKeyInputLeftArrow, UIKeyInputRightArrow, UIKeyInputUpArrow, UIKeyInputDownArrow, UIKeyInputEscape])

		let action = #selector(KeyBindingInputControl.commandAction(_:))

		for input in inputs
		{
			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.command], action: action))
			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.shift], action: action))
			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.control], action: action))
			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.alternate], action: action))

			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.command, .control], action: action))
			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.command, .shift], action: action))
			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.command, .alternate], action: action))

			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.shift, .control], action: action))
			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.shift, .alternate], action: action))

			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.control, .alternate], action: action))
		}

		self._keyCommands = keyCommands
	}

	override var canBecomeFirstResponder: Bool
	{
		return true
	}

	override var keyCommands: [UIKeyCommand]?
	{
		return _keyCommands
	}

	@objc func commandAction(_ sender: Any?)
	{
		if let keyCommand = sender as? UIKeyCommand
		{
			if KeyBindingsRegistry.default.forbiddenKeyCommands.contains(keyCommand)
			{
				NSLog("NOPE")
				return
			}

			newBindingAction?(keyCommand)
		}
	}
}

class KeyBindingEditorView: UIView
{
	var viewController: KeyBindingEditorViewController? = nil

	@IBOutlet var keyBindingDisplayLabel: KeyBindingLabel!
	@IBOutlet var instructionsLabel: UILabel!
	@IBOutlet var unassignedLabel: UILabel!
	@IBOutlet var saveButton: UIButton!
	@IBOutlet var unassignButton: UIButton!

	@IBAction func save(sender: Any?)
	{
		viewController?.save()
	}

	@IBAction func unassign(_ sender: Any?)
	{
		viewController?.unassign()
	}
}
