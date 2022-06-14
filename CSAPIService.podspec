

Pod::Spec.new do |s|
  s.name             = 'CSAPIService'
  s.version          = '0.0.4'
  s.summary          = 'Swift 网络抽象层'
  s.description      = <<-DESC
                       Swift 网络抽象层，角色分明
                       DESC

  s.homepage         = 'https://github.com/Coder-Star/APIService'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'CoderStar' => '1340529758@qq.com' }
  s.source           = { :git => 'https://github.com/Coder-Star/APIService.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.swift_version = '5.0'
  s.module_name = 'APIService'

  s.source_files = 'APIService/Classes/**/*'

  s.dependency 'Alamofire','4.9.1'


  # s.resource_bundles = {
  #   'APIService' => ['APIService/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
end
