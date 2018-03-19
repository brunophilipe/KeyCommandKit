Pod::Spec.new do |spec|
  spec.name = 'KeyCommandKit'
  spec.version = '1.0'
  spec.homepage = 'https://github.com/brunophilipe/KeyCommandKit'
  spec.source = {:git => 'https://github.com/brunophilipe/KeyCommandKit.git'}
  spec.authors = {'Bruno Philipe' => 'me@bruno.ph'}
  spec.summary = 'Library to manager, customize, and store UIKeyCommands.'
  spec.license = { :type => 'LGPL', :file => 'LICENSE' }

  spec.ios.deployment_target = '9.0'
  spec.ios.frameworks = 'Foundation', 'UIKit'

  spec.source_files = 'KeyCommandKit/*.{h,m,swift,xib}'
  spec.resources = 'KeyCommandKit/Media.xcassets'
  spec.module_name = 'KeyCommandKit'
end
