//
//  KeyBindingEditorViewController.swift
//  KeyCommandKit - Provides customizable key commands to iOS Apps
//
//  Created by Bruno Philipe on 3/7/17.
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
		keyBindingControl.conflictAction =
			{
				(conflict, keyCommand) in self.showConflictAlert(for: conflict, with: keyCommand)
			}
		keyBindingControl.newBindingAction =
			{
				keyCommand in self.storeNewBinding(with: keyCommand)
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
		guard let originalBinding = (binding as? CustomizedKeyBinding)?.originalBinding else
		{
			dismiss(animated: true)
			return
		}

		if let conflictingBinding = KeyBindingsRegistry.default.firstBinding(equivalentTo: originalBinding)
		{
			showRevertConflictAlert(for: conflictingBinding)
		}
		else
		{
			result = .revert
			dismiss(animated: true)
		}
	}

	@objc func cancel()
	{
		result = nil
		dismiss(animated: true)
	}

	@objc func unassign()
	{
		result = .unassign
		dismiss(animated: true)
	}

	enum EditorResult
	{
		case customize(KeyBinding)
		case unsassignAndCustomize(KeyBindingsRegistry.BindingConflict, KeyBinding)
		case revert
		case revertAndUnassign(KeyBindingsRegistry.BindingConflict)
		case revertBoth(KeyBindingsRegistry.BindingConflict)
		case unassign
	}

	// Private

	func storeNewBinding(with keyCommand: UIKeyCommand, unassigning: KeyBindingsRegistry.BindingConflict? = nil)
	{
		let binding = KeyBinding(key: "", name: "",
								 input: keyCommand.input!, modifiers: keyCommand.modifierFlags,
								 isDiscoverable: false)

		let customizedBinding = binding.customized(input: binding.input, modifiers: binding.modifiers)

		if let unassignedBinding = unassigning
		{
			result = .unsassignAndCustomize(unassignedBinding, customizedBinding)
		}
		else
		{
			result = .customize(customizedBinding)
		}

		updateLabels()
	}

	func reverBindingUnassigning(_ unassigning: KeyBindingsRegistry.BindingConflict)
	{
		result = .revertAndUnassign(unassigning)
		dismiss(animated: true)
	}

	func reverBindingAndRevertConflict(_ conflict: KeyBindingsRegistry.BindingConflict)
	{
		result = .revertBoth(conflict)
		dismiss(animated: true)
	}

	private func showConflictAlert(for conflictingBinding: KeyBindingsRegistry.BindingConflict, with keyCommand: UIKeyCommand)
	{
		let conflictName = conflictingBinding.binding.name

		let alert = UIAlertController(title: "Binding in Use",
									  message: "The inserted key command is already being used: “\(conflictName)”",
			preferredStyle: .alert)

		alert.addAction(UIAlertAction(title: "Unassign “\(conflictName)”", style: .destructive, handler: { (_) in
			self.storeNewBinding(with: keyCommand, unassigning: conflictingBinding)
		}))

		alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))

		present(alert, animated: true, completion: nil)
	}

	private func showRevertConflictAlert(for conflictingBinding: KeyBindingsRegistry.BindingConflict)
	{
		let conflictName = conflictingBinding.binding.name

		let alert = UIAlertController(title: "Binding in Use",
									  message: "The original key command is currently assigned: “\(conflictName)”",
			preferredStyle: .alert)

		alert.addAction(UIAlertAction(title: "Unassign “\(conflictName)” and revert", style: .destructive, handler: { (_) in
			self.reverBindingUnassigning(conflictingBinding)
		}))

		alert.addAction(UIAlertAction(title: "Revert Both", style: .destructive, handler: { (_) in
			self.reverBindingAndRevertConflict(conflictingBinding)
		}))

		alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))

		present(alert, animated: true, completion: nil)
	}

	private func updateLabels()
	{
		guard let editorView = self.editorView else
		{
			// If there's no editor view, there are no labels to update!
			return
		}

		let binding: KeyBinding

		// If there is a customized binding set, we read from there
		switch result
		{
		case .some(.customize(let newBinding)), .some(.unsassignAndCustomize(_, let newBinding)):
			binding = newBinding

		default:
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

	var conflictAction: ((KeyBindingsRegistry.BindingConflict, UIKeyCommand) -> Void)? = nil

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

		inputs.append(contentsOf: [UIKeyInputLeftArrow, UIKeyInputRightArrow, UIKeyInputUpArrow, UIKeyInputDownArrow, UIKeyInputEscape, UIKeyInputTab])

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

		keyCommands.append(UIKeyCommand(input: UIKeyInputTab, modifierFlags: [], action: action))

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
			let registry = KeyBindingsRegistry.default

			if registry.forbiddenKeyCommands.contains(keyCommand)
			{
				return
			}

			if let bindingConflict = registry.firstBinding(equivalentTo: keyCommand)
			{
				conflictAction?(bindingConflict, keyCommand)
			}
			else
			{
				newBindingAction?(keyCommand)
			}
		}
	}
}

public class KeyBindingEditorView: UIView
{
	var viewController: KeyBindingEditorViewController? = nil

	@IBOutlet public var keyBindingDisplayLabel: KeyBindingLabel!
	@IBOutlet public var instructionsLabel: UILabel!
	@IBOutlet public var unassignedLabel: UILabel!
	@IBOutlet public var saveButton: UIButton!
	@IBOutlet public var unassignButton: UIButton!

	@IBAction func save(sender: Any?)
	{
		viewController?.save()
	}

	@IBAction func unassign(_ sender: Any?)
	{
		viewController?.unassign()
	}
}
