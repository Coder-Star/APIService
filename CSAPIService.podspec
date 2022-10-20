Pod::Spec.new do |s|
    s.name             = 'CSAPIService'
    s.version          = '0.0.8'
    s.summary          = 'Swift 网络抽象层'
    s.description      = <<-DESC
    Swift 网络抽象层，角色分明
    DESC

    s.homepage         = 'https://github.com/Coder-Star/APIService'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'CoderStar' => '1340529758@qq.com' }
    s.source           = { :git => 'https://github.com/Coder-Star/APIService.git', :tag => s.version.to_s }

    s.swift_version = '5.0'
    s.module_name = 'APIService'
    s.ios.deployment_target = '11.0'

    # 第一层
    s.subspec 'Core' do |core|
        core.source_files = 'APIService/Classes/Core/**/*'
        core.dependency 'Alamofire','4.9.1'
    end

    # 第二层

    s.subspec 'Plugin' do |plugin|
        plugin.dependency 'CSAPIService/Core'
        plugin.source_files = 'APIService/Classes/Plugin/**/*'
    end

    s.subspec 'Cache' do |cache|
        cache.source_files = 'APIService/Classes/Cache/**/*'
        cache.dependency 'CSAPIService/Core'
        cache.dependency 'Cache','6.0.0'
    end



end
