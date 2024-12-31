Pod::Spec.new do |s|

 s.name             = "GStoreKit"
 s.version           = "0.0.4"
 s.summary         = "RxStoreKit rewrite with Combine"
 s.homepage        = "https://github.com/my1325/GStoreKit.git"
 s.license            = "MIT"
 s.platform          = :ios, "13.0"
 s.authors           = { "my1325" => "1173962595@qq.com" }
 s.source             = { :git => "https://github.com/my1325/GStoreKit.git", :tag => "#{s.version}" }
 s.swift_version = '5.0'
 s.default_subspecs = 'StoreKitCore'

 s.subspec 'StoreKitCore' do |ss|
 	ss.source_files = 'StoreKitCore/*.swift'
 end

 s.subspec 'CombineStoreKit' do |ss|
 	ss.source_files = 'SKCombine/*.swift'
 	ss.dependency 'CombineStoreKit/StoreKitCore'
 	ss.dependency 'CombineExt'
 end 

 s.subspec 'AsyncStoreKit' do |ss|
 	ss.source_files = 'AsyncStoreKit/*.swift'
 	ss.dependency 'GStoreKit/StoreKitCore'
 end

end
