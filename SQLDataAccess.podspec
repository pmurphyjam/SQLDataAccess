#
# Be sure to run `pod lib lint SQLDataAccess.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SQLDataAccess'
  s.version          = '0.1.4'
  s.summary          = 'SQLDataAccess is a library used to facilitate using SQLite in iOS.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
SQLDataAccess makes writing SQL query statements for SQLite databases easy and a joy to work with in iOS! SQLDataAccess also works for large SQL Transactions speeding up performance dramatically on any kind of query. Need a HIPAA compliant database for security? SQLDataAccess is super easy to integrate with SQLCipher from (www.zetetic.net). Now you can have both worlds, easy of use, and 256 bit AES encryption along with phenomenal performace!
                       DESC

  s.homepage         = 'https://github.com/pmurphyjam/SQLDataAccess'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'pmurphyjam' => 'pmurphyjam@gmail.com' }
  s.source           = { :git => 'https://github.com/pmurphyjam/SQLDataAccess.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/pmurphyjam'

  s.ios.deployment_target = '10.0'

  s.source_files = 'SQLDataAccess/Classes/**/*'

# This libraries command makes it work, otherwise it gets 'Undefined symbols for architecture x86_64' during linking
  s.libraries = 'sqlite3'

  # s.resource_bundles = {
  #   'SQLDataAccess' => ['SQLDataAccess/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

end
