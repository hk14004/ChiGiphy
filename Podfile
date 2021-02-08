# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'ChiGiphy' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!
  # Pods for ChiGiphy
  pod 'RxSwift', '~> 4'
  pod 'RxCocoa', '~> 4'
  pod 'RxDataSources', '~> 3.1'
  pod 'Action', '~> 3.9'
  pod 'Gifu'
  pod 'Cartography', '~> 3.0'
  pod 'NVActivityIndicatorView'
  pod 'SCLAlertView'
  pod 'RxSwiftExt'
  
  target 'ChiGiphyTests' do
      inherit! :search_paths
      pod 'RxBlocking', '4.5.0'
      pod 'RxTest', '4.5.0'
  end

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      end
    end
  end
end

