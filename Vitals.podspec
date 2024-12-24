#
# Be sure to run `pod lib lint Vitals.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Vitals'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Vitals.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/zhiying-fan/Vitals'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zhiying-fan' => 'fanzhiying1992@gmail.com' }
  s.source           = { :http => 'https://github.com/zhiying-fan/Vitals/releases/download/0.0.1/Vitals.xcframework.zip' }

  s.ios.deployment_target = '13.0'
  s.static_framework = true
  s.vendored_frameworks = 'Vitals.xcframework'
  
  s.dependency 'MediaPipeTasksVision', '0.10.14'
end
