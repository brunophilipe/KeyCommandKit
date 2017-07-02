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

	var completion: (() -> Void)? = nil

	init(binding: KeyBinding)
	{
		self.binding = binding
		super.init(nibName: nil, bundle: nil)

		self.preferredContentSize = CGSize(width: 375.0, height: 300.0)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad()
	{
		super.viewDidLoad()

		navigationItem.title = binding.name

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

		let inputView = UITextField(frame: view.bounds)
		inputView.textColor = cellTextColor
		inputView.textAlignment = .center
		inputView.delegate = self
		inputView.tintColor = UIColor.clear
		view.addSubview(inputView)

		let keyBindingControl = KeyBindingInputControl(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
		keyBindingControl.newBindingAction =
			{
				keyCommand in

				inputView.text = KeyBinding(key: "", name: "", input: keyCommand.input!, modifiers: keyCommand.modifierFlags, isDiscoverable: false).stringRepresentation
				inputView.font = UIFont.systemFont(ofSize: 36.0)
		}

		view.addSubview(keyBindingControl)

		keyBindingControl.becomeFirstResponder()
	}

	override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)

		DispatchQueue.main.async
			{
				self.completion?()
		}
	}

	@objc func revert()
	{

	}

	@objc func cancel()
	{
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
		let characters = "abcdefghijklmnopqrstuvwxyz!\"#$%&'()*+,-./0123456789:;<=>?@[\\]^_`´{|}~".characters

		var keyCommands = [UIKeyCommand]()

		for character in characters
		{
			keyCommands.append(UIKeyCommand(input: String(character), modifierFlags: [.command], action: #selector(KeyBindingInputControl.commandAction(_:))))
			keyCommands.append(UIKeyCommand(input: String(character), modifierFlags: [.shift], action: #selector(KeyBindingInputControl.commandAction(_:))))
			keyCommands.append(UIKeyCommand(input: String(character), modifierFlags: [.control], action: #selector(KeyBindingInputControl.commandAction(_:))))
			keyCommands.append(UIKeyCommand(input: String(character), modifierFlags: [.alternate], action: #selector(KeyBindingInputControl.commandAction(_:))))

			keyCommands.append(UIKeyCommand(input: String(character), modifierFlags: [.command, .control], action: #selector(KeyBindingInputControl.commandAction(_:))))
			keyCommands.append(UIKeyCommand(input: String(character), modifierFlags: [.command, .shift], action: #selector(KeyBindingInputControl.commandAction(_:))))
			keyCommands.append(UIKeyCommand(input: String(character), modifierFlags: [.command, .alternate], action: #selector(KeyBindingInputControl.commandAction(_:))))

			keyCommands.append(UIKeyCommand(input: String(character), modifierFlags: [.shift, .control], action: #selector(KeyBindingInputControl.commandAction(_:))))
			keyCommands.append(UIKeyCommand(input: String(character), modifierFlags: [.shift, .alternate], action: #selector(KeyBindingInputControl.commandAction(_:))))

			keyCommands.append(UIKeyCommand(input: String(character), modifierFlags: [.control, .alternate], action: #selector(KeyBindingInputControl.commandAction(_:))))
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
