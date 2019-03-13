#
# Be sure to run `pod lib lint Novagraph.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Novagraph'
  s.version          = '1.1.6'
  s.summary          = 'Utilies to access Novagraph and work with using Core Data.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  This cocoapod comes with some Core Data helpers and a thin network layer made to easily access Novagraph servers.
                       DESC

  s.homepage         = 'https://github.com/sophaz/novagraph-ios'
  s.swift_version    = '4.2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sophie Novati' => 'sophie@buildschool.com' }
  s.source           = { :git => 'https://github.com/sophaz/novagraph-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'Source/**', 'Cognito/**'
  
  # s.resource_bundles = {
  #   'Novagraph' => ['Novagraph/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'

  s.dependency 'Alamofire'
  s.dependency 'AWSCognito', '~> 2.8.2'
  s.dependency 'AWSCognitoIdentityProvider', '~> 2.8.2'
  s.dependency 'AWSCognitoAuth', '~> 2.8.2'

end
