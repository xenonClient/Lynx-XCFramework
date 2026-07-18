platform :ios, '12.0'

target 'Lynx-MiniApp' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'Lynx', '3.9.0', :subspecs => [
    'Framework',
  ]
  pod 'PrimJS', '3.9.1', :subspecs => ['quickjs', 'napi']

  pod 'LynxService', '3.9.0', :subspecs => [
      'Image',
      'Http',
  ]

  # ImageService dependencies:
  pod 'SDWebImage','5.15.5'
  pod 'SDWebImageWebPCoder', '0.11.0'
  pod 'XElement', '3.9.0'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
