//
//  KeyBindingEditorViewController.swift
//  KeyCommandKit
//
//  Created by Bruno Philipe on 3/7/17.
//  Copyright © 2017 Bruno Philipe. All rights reserved.
//

import UIKit

class KeyBindingEditorViewController: UIViewController
{
	var cellBackgroundColor: UIColor? = nil
	var cellTextColor: UIColor? = nil

	var binding: KeyBinding

	var updatedBinding: KeyBinding?

	var completion: ((KeyBinding?) -> Void)? = nil

	var editorView: KeyBindingEditorView?
	{
		return view as? KeyBindingEditorView
	}

	init(binding: KeyBinding)
	{
		self.binding = binding
		self.updatedBinding = binding
		super.init(nibName: "KeyBindingEditorView", bundle: Bundle(for: KeyBindingEditorViewController.self))

		self.preferredContentSize = CGSize(width: 275.0, height: 200.0)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad()
	{
		super.viewDidLoad()

		editorView?.viewController = self
		editorView?.keyBindingDisplayLabel.keyBinding = binding

		navigationItem.title = ""

		if binding is CustomizedKeyBinding
		{
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Revert",
			                                                    style: .plain,
			                                                    target: self,
			                                                    action: #selector(KeyBindingEditorViewController.revert))
		}
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		editorView?.keyBindingDisplayLabel.color = cellTextColor ?? .darkText
		editorView?.backgroundColor = cellBackgroundColor

		let keyBindingControl = KeyBindingInputControl(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
		keyBindingControl.newBindingAction =
			{
				keyCommand in

				let binding = KeyBinding(key: "", name: "",
				                         input: keyCommand.input!, modifiers: keyCommand.modifierFlags,
				                         isDiscoverable: false)

				self.editorView?.keyBindingDisplayLabel.keyBinding = binding
//				self.editorView?.keyBindingDisplayLabel.font = UIFont.systemFont(ofSize: 36.0)

				self.updatedBinding = self.binding.customized(input: binding.input, modifiers: binding.modifiers)
			}

		view.addSubview(keyBindingControl)

		keyBindingControl.becomeFirstResponder()
	}

	override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)

		DispatchQueue.main.async
			{
				self.completion?(self.updatedBinding)
			}
	}

	@objc func revert()
	{
		self.updatedBinding = nil

		dismiss(animated: true, completion: nil)
	}

	@objc func cancel()
	{
		self.updatedBinding = self.binding

		dismiss(animated: true, completion: nil)
	}
}

extension KeyBindingEditorViewController: UITextFieldDelegate
{
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
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

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func makeKeyCommands()
	{
		let special = UIKeyInputBackspace + UIKeyInputTab + UIKeyInputReturn + UIKeyInputDelete
		let characters = "\(special)abcdefghijklmnopqrstuvwxyz!\"#$%&'()*+,-./0123456789:;<=>º?@[\\]^_`´{|}~"

		var keyCommands = [UIKeyCommand]()

		var inputs = characters.map({ String($0) })

		inputs.append(contentsOf: [UIKeyInputLeftArrow, UIKeyInputRightArrow, UIKeyInputUpArrow, UIKeyInputDownArrow, UIKeyInputEscape])

		for input in inputs
		{
			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.command], action: #selector(KeyBindingInputControl.commandAction(_:))))
			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.shift], action: #selector(KeyBindingInputControl.commandAction(_:))))
			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.control], action: #selector(KeyBindingInputControl.commandAction(_:))))
			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.alternate], action: #selector(KeyBindingInputControl.commandAction(_:))))

			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.command, .control], action: #selector(KeyBindingInputControl.commandAction(_:))))
			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.command, .shift], action: #selector(KeyBindingInputControl.commandAction(_:))))
			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.command, .alternate], action: #selector(KeyBindingInputControl.commandAction(_:))))

			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.shift, .control], action: #selector(KeyBindingInputControl.commandAction(_:))))
			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.shift, .alternate], action: #selector(KeyBindingInputControl.commandAction(_:))))

			keyCommands.append(UIKeyCommand(input: input, modifierFlags: [.control, .alternate], action: #selector(KeyBindingInputControl.commandAction(_:))))
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
			newBindingAction?(keyCommand)
		}
	}
}

class KeyBindingEditorView: UIView
{
	var viewController: KeyBindingEditorViewController? = nil

	@IBOutlet var keyBindingDisplayLabel: KeyBindingLabel!

	@IBAction func save(sender: Any?)
	{
		 viewController?.dismiss(animated: true, completion: nil)
	}
}
