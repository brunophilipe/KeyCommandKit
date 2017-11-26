//
//  KeyBindingLabel.swift
//  KeyCommandKit
//
//  Created by Bruno Philipe on 26/11/17.
//

import UIKit

@IBDesignable
class KeyBindingLabel: UIView
{
	@IBInspectable var color: UIColor = .darkText

	@IBInspectable var targetHeight: CGFloat = 28

	var keyBinding: KeyBinding? = nil
	{
		didSet
		{
			buildKeyCommandRepresentation()
		}
	}

	@IBOutlet var modifiersStackView: UIStackView!
	@IBOutlet var inputStackView: UIStackView!

	func buildKeyCommandRepresentation()
	{
		buildKeyModifiersRepresentation()
		buildKeyInputRepresentation()
	}

	private func buildKeyModifiersRepresentation()
	{
		let views = modifiersStackView.arrangedSubviews

		for view in views
		{
			modifiersStackView.removeArrangedSubview(view)
			view.removeFromSuperview()
		}

		guard let modifiers = keyBinding?.modifiers else
		{
			return
		}

		if modifiers.contains(.control)
		{
			modifiersStackView.addArrangedSubview(makeImage("control"))
		}

		if modifiers.contains(.alternate)
		{
			modifiersStackView.addArrangedSubview(makeImage("option"))
		}

		if modifiers.contains(.shift)
		{
			modifiersStackView.addArrangedSubview(makeImage("shift"))
		}

		if modifiers.contains(.command)
		{
			modifiersStackView.addArrangedSubview(makeImage("command"))
		}
	}

	private func buildKeyInputRepresentation()
	{
		let views = inputStackView.arrangedSubviews

		for view in views
		{
			inputStackView.removeArrangedSubview(view)
			view.removeFromSuperview()
		}

		guard let input = keyBinding?.input else
		{
			return
		}

		switch input
		{
		case UIKeyInputLeftArrow:
			inputStackView.addArrangedSubview(makeImage("left"))

		case UIKeyInputRightArrow:
			inputStackView.addArrangedSubview(makeImage("right"))

		case UIKeyInputUpArrow:
			inputStackView.addArrangedSubview(makeImage("up"))

		case UIKeyInputDownArrow:
			inputStackView.addArrangedSubview(makeImage("down"))

		case UIKeyInputEscape:
			inputStackView.addArrangedSubview(makeImage("esc"))

		case UIKeyInputBackspace:
			inputStackView.addArrangedSubview(makeImage("backspace"))

		case UIKeyInputDelete:
			inputStackView.addArrangedSubview(makeImage("delete"))

		case UIKeyInputTab:
			inputStackView.addArrangedSubview(makeImage("tab"))

		case UIKeyInputReturn:
			inputStackView.addArrangedSubview(makeImage("return"))

		default:
			inputStackView.addArrangedSubview(makeLabel(input.uppercased()))
		}
	}

	lazy var attributes: [NSAttributedStringKey: Any] = [
		.paragraphStyle: paragraphStyle,
		.foregroundColor: UIColor.white,
		.font: UIFont.systemFont(ofSize: targetHeight * 1.35)
	]

	lazy var paragraphStyle: NSParagraphStyle =
	{
		var paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineSpacing = targetHeight * 0.285
		paragraphStyle.paragraphSpacing = 0
		paragraphStyle.headIndent = 0
		paragraphStyle.tailIndent = 0
		paragraphStyle.firstLineHeadIndent = 0
		paragraphStyle.minimumLineHeight = targetHeight
		paragraphStyle.maximumLineHeight = 0
		paragraphStyle.tabStops = nil
		paragraphStyle.defaultTabInterval = 0
		return paragraphStyle
	}()

	private func makeLabel(_ text: String) -> UILabel
	{
		let label = UILabel()
		label.attributedText = NSAttributedString(string: text, attributes: attributes)
		label.clipsToBounds = false
		label.textColor = color
		return label
	}

	private func makeImage(_ name: String) -> UIView
	{
		let image = UIImage(named: name, in: Bundle(for: KeyBindingLabel.self), compatibleWith: nil)
		let maskView = UIImageView(image: image)
		maskView.contentMode = .center

		if let image = image
		{
			let colorView = UIView(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
			colorView.backgroundColor = color
			colorView.mask = maskView

			colorView.widthAnchor.constraint(greaterThanOrEqualToConstant: image.size.width).isActive = true

			return colorView
		}
		else
		{
			return maskView
		}
	}
}
