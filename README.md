# KeyCommandKit

Provide customizable key commands in your iOS App.

## What it is

This is a self-contained library that allows users of your App to customize the key commands you use in your App. It does this by defining key binding providers, key command factories, and a built-in interface to list and customize the key bindings used by your App. This library provides everything you need to allow user customization of key commands, so integrating it to your app is not a one-liner. However the complexity provides a very powerful and user-friendly end-product.

## How it works

**KeyCommandKit** manufactures `UIKeyCommands` based on registered bindings and assigned actions. This gets a little bit complicated (for a good reason), so read the glossary below:

### Glossary:

* **Key Binding**: A simple combination of an input key (letter) and a modifier key, identified by a key (string), but without any actions attached to it.
* **Key Binding Provider**: Someone that defines **Key Bindings**, if they are discoverable, and their discoverability names.
* **Key Binding Registry**: Where **Key Binding Providers** are registered, and for whom the App requests `UIKeyCommands` to be manufactured based on the user's customizations (if any).

### Classes:

* `KeyBinding`: A struct representing a **Key Binding**
* `KeyBindingProvider`: A protocol that defines the required methods a **Key Bindings Provider** should implement.
* `KeyBindingsRegistry`: A singleton class (call `KeyBindingsRegistry.default`) that manages the registering, manufacturing, and storage of customized **Key Bindings**.
* `KeyBindingsViewController`: A subclass of `UITableViewController` that fetches all **Key Bindings** registered by **Key Binding Providers**, displays their input combos and their names, and allows the user to customize or disable individual bindings.
* `KeyCommandLabel`: A subclass of `UIView` that renders the input and modifiers of a `UIKeyCommand` in a user-friendly way using images.

### Extras

`KeyCommandKit` also defines helpful constants for some keys forgotten by Apple:

* `UIKeyInputBackspace`: The backspace key (backwards delete).
* `UIKeyInputTab`: The tab key.
* `UIKeyInputReturn`: The return key.
* `UIKeyInputDelete`: The delete key (forwards delete).

## How to use

Install this library either by cloning the repo and embedding the source files or by using CocoaPods:

```
TODO
```

After the library is included in your project, you will have to import it (if you used CocoaPods):

```swift
import KeyCommandKit
```

Then you need to set the Application Support directory name. This is used to initialize the read/write of customizations and is a required step:

```swift
class AppDelegate: UIResponder, UIApplicationDelegate
{
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: AppLaunchOptions) -> Bool
	{
		KeyBindingsRegistry.default.applicationSupportName = "YourAppName"
		
		...
	}
{
```

Create an extension of the class (usually a view controller) where you want to provide `UIKeyCommands` complying to `KeyBindingsProvider`:

```swift
extension MailboxViewController: KeyBindingsProvider
{
	static func provideKeyBindings() -> [KeyBinding]
	{
		// Define each desired key binding by giving them a unique identifier key, a user-friendly
		// name, the default input key, the default modifiers, and whether this binding is 
		// discoverable to the user (shows up when user holds down the Command key).
		return [
			KeyBinding(key: "new-email", name: "Compose New Email", input: "N", modifiers: .command, isDiscoverable: true),
			KeyBinding(key: "forward-email", name: "Forward Email", input: "F", modifiers: [.command, .shift], isDiscoverable: true),
		]
	}

	static var providerName: String
	{
		// User friendly name for this provider, bet to use the same title as the view controller
		// if possible.
		return "Mailbox"
	}
}
```

Now you need to tell the registry about the provider you just declared. Do so right after you initialize the library in `AppDelegate`:

```swift
class AppDelegate: UIResponder, UIApplicationDelegate
{
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: AppLaunchOptions) -> Bool
	{
		KeyBindingsRegistry.default.applicationSupportName = "YourAppName"
		
		do
		{
			// Register all the key bindings providers
			try registry.register(provider: MailboxViewController.self)
		}
		catch let error
		{
			NSLog("Could not register key bindings for provider: \(error)")
		}
		
		...
	}
{
```

Now in order to use the key bindings, you have to replace your override of `keyCommands` with the factory for your provider's key bindings.

Supposing you had this as your `keyCommands` override:

```swift
class MailboxViewController: UIViewController
{
	override var keyCommands: [UIKeyCommand]
	{
		return [
			UIKeyCommand(input: "N", modifierFlags: .command, action: #selector(MailboxViewController.composeNewEmail(_:)), discoverabilityTitle: "Compose New Email"),
			UIKeyCommand(input: "F", modifierFlags: [.command, .shift], action: #selector(MailboxViewController.forwardEmail(_:)), discoverabilityTitle: "Forward Email"),
		]
	}
}
```

...replace it with with this factory:

```swift
class MailboxViewController: UIViewController
{
	override var keyCommands: [UIKeyCommand]
	{
		return KeyBindingsRegistry.default.bindings(forProvider: MailboxViewController.self).make(withActionsForKeys: [
			("new-email", #selector(MailboxViewController.composeNewEmail(_:))),
			("forward-email", #selector(MailboxViewController.forwardEmail(_:))),
		])
	}
}
```

`bindings(forProvider:)` fetches all registered key bindings for the given provider, loads any overrides the user might have set, and returns them. Then, `make(withActionsForKeys:)` builds individual `UIKeyCommand` instances by using the input, modifiers, name, and discoverability flag of the bindings and matches them with the given selector with the same key as the key in each binding (declared in the `provideKeyBindings()` class method).

On top of that, the `make(withActionsForKeys:)` will skip any bindings that the user has unassigned, so they don't end up in the `keyCommands` array at.

### Using `KeyBindingsViewController`

This view controller is self-contained, and all you need to do is to show it in your navigation stack. If you are using a table view controller for your preferences, for example:

```swift
class YourPreferencesViewController: UITableViewController
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		switch (indexPath.section, indexPath.row)
		{
		case (0, _KeyBindingsRowIndex_):
			// You can use either .grouped or .plain styles, both look great.
			navigationController?.pushViewController(KeyBindingsViewController(style: .grouped), animated: true)
		}
	}
}
```

You can also do this from a Storyboard.
