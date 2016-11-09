Pod::Spec.new do |s|
  s.name         = "ObservableArray-RxSwift"
  s.version      = "0.1.0"
  s.summary      = "ObservableArray is an array that can emit messages of elements and diffs on it's changing."
  s.homepage     = "https://github.com/safx/ObservableArray-RxSwift"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "MATSUMOTO Yuji" => "safxdev@gmail.com" }
  s.source       = { :git => "https://github.com/safx/ObservableArray-RxSwift.git", :tag => s.version }
  s.source_files = "ObservableArray/*.swift"
  s.ios.deployment_target = "8.4"
  s.osx.deployment_target = "10.10"
  s.dependency     "RxSwift", '~> 3.0'
  s.requires_arc = true
end
