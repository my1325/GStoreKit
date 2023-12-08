Pod::Spec.new do |s|

 s.name             = "CombineStoreKit"
 s.version           = "0.0.1"
 s.summary         = "RxStoreKit rewrite with Combine"
 s.homepage        = "https://github.com/my1325/CombineStoreKit.git"
 s.license            = "MIT"
 s.platform          = :ios, "13.0"
 s.authors           = { "my1325" => "1173962595@qq.com" }
 s.source             = { :git => "https://github.com/my1325/CombineStoreKit.git", :tag => "#{s.version}" }
 s.swift_version = '5.0'
 s.source_files = 'CombineStoreKit/*.swift'
 s.dependency 'CombineExt'
end
