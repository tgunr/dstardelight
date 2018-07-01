# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

workspace 'DStarDelight.xcworkspace'

target 'DStarEngine' do
    use_frameworks!
    project 'Frameworks/DStarEngine/DStarEngine.xcodeproj'
    inherit! :search_paths
    platform :osx, 10.13

    pod 'Objection', '1.6.1'
    pod 'Typhoon'

end

target 'DStarDelight' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  project 'DStarDelight/DStarDelight.xcodeproj'
  platform :osx, 10.13
  inherit! :search_paths

  # Pods for DStarDelight
  pod 'Objection', '1.6.1'
  pod 'Typhoon'

  target 'DStarDelightUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'DStarDelightIOS' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  project 'DStarDelightIOS/DStarDelightIOS.xcodeproj'
  platform :ios, '12.0'
  inherit! :search_paths

  # Pods for DStarDelightIOS
  pod 'SwiftSocket'
  pod 'Objection', '1.6.1'

  target 'DStarDelightIOSUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
