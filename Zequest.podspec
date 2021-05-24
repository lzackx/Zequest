#
# Be sure to run `pod lib lint Zequest.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Zequest'
  s.version          = '1.0.0'
  s.summary          = 'A common request tool'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
A common request tool
                       DESC

  s.homepage         = 'https://github.com/lzackx/Zequest'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lzackx' => 'lzackx@lzackx.com' }
  s.source           = { :git => 'https://github.com/lzackx/Zequest.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = [
	'Zequest/Classes/**/*.{h,m}',
  ]
  s.public_header_files = [
	'Zequest/Classes/Zequest.h',
  ]
  s.private_header_files = [
	'Zequest/Classes/ZequestPrivate.h',
	'Zequest/Classes/Zequest+Cache.h',
  ]
  
  # s.resource_bundles = {
  #   'Zequest' => ['Zequest/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'AFNetworking'
  s.dependency 'YYKit'
end
