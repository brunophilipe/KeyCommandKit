//
//  KeyBindingLabel.swift
//  KeyCommandKit - Provides customizable key commands to iOS Apps
//
//  Created by Bruno Philipe on 26/11/17.
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
public class KeyBindingLabel: UIView
{
	private var needsUpdate: Bool = false

	@IBInspectable public var color: UIColor = .darkText
	{
		didSet
		{
			needsUpdate = true
			setNeedsDisplay()
		}
	}

	@IBInspectable public var targetHeight: CGFloat = 28
	{
		didSet
		{
			needsUpdate = true
			setNeedsDisplay()
		}
	}

	public var keyBinding: KeyBinding? = nil
	{
		didSet
		{
			needsUpdate = true
			setNeedsDisplay()
		}
	}

	@IBOutlet public var modifiersStackView: UIStackView!
	@IBOutlet public var inputStackView: UIStackView!

	public override func draw(_ rect: CGRect)
	{
		if needsUpdate && keyBinding != nil
		{
			buildKeyCommandRepresentation()
			needsUpdate = false
		}

		super.draw(rect)
	}

	public func buildKeyCommandRepresentation()
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
		paragraphStyle.lineSpacing = 0
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
		maskView.contentMode = .scaleAspectFit

		if let image = image
		{
			let colorView = FillView(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
			colorView.fillColor = color
			colorView.translatesAutoresizingMaskIntoConstraints = false
			colorView.widthAnchor.constraint(greaterThanOrEqualToConstant: image.size.width).isActive = true

			let containerHeight = bounds.height
			let targetHeight = self.targetHeight
			maskView.frame = CGRect(x: 0, y: containerHeight / 2 - targetHeight / 2, width: targetHeight * 1.3, height: targetHeight)

			colorView.mask = maskView

			return colorView
		}
		else
		{
			return maskView
		}
	}
}

class FillView: UIView
{
	var fillColor: UIColor = .white

	override func draw(_ rect: CGRect)
	{
		fillColor.setFill()
		UIRectFill(rect)
	}
}
