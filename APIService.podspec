

Pod::Spec.new do |s|
  s.name             = 'APIService'
  s.version          = '0.1.0'
  s.summary          = 'A short description of APIService.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Coder-Star/APIService'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'CoderStar' => '1340529758@qq.com' }
  s.source           = { :git => 'https://github.com/Coder-Star/APIService.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'APIService/Classes/**/*'
  s.dependency 'Alamofire','4.9.1'

  # s.resource_bundles = {
  #   'APIService' => ['APIService/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
end
