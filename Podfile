# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

workspace 'DStarDelight.xcworkspace'

target 'DStarDelight' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  project 'DStarDelight/DStarDelight.xcodeproj'
  platform :osx, 10.14
  inherit! :search_paths

  # Pods for DStarDelight
  pod 'Dispatch'
  pod 'NSObjectCoder'
  pod 'AutoCoding'
  pod 'Log'
  pod 'RxSwift',    '~> 4.0'
  pod 'RxCocoa',    '~> 4.0'

  target 'DStarDelightUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

