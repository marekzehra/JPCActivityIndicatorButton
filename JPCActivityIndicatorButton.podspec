Pod::Spec.new do |s|

  s.name         = "JPCActivityIndicatorButton"
  s.version      = "1.0.0"
  s.summary      = "An implementation of the progress control used in the App Store app with styling inspired by Google's material design."

  s.description  = <<-DESC
  It is a drop in replacement for UIActivityIndicatorView and UIProgressView that tracks touch input like a UIButton. It may be useful in the following scenarios
* Replacement for UIActivityIndicatorView
* Replacement for UIProgressView
* Replacement for UIButton with Google Material Design styling
* To create a similar interaction as start and stopping downloads in the App Store app.
                   DESC

  s.homepage     = "https://github.com/jpchmura/JPCActivityIndicatorButton"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = 'Jon Chmura'
  s.social_media_url   = "http://twitter.com/jpchmura"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/jpchmura/JPCActivityIndicatorButton.git", :tag => "v1.0.0" }
  s.source_files  = "Source/*.swift"

end
