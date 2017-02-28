Pod::Spec.new do |s|
  s.name             = "KZNodes"
  s.version          = "0.1.3"
  s.summary          = "Framework for building visual workflow editors eg. Origami."
  s.description      = <<-DESC
                      Have you ever wondered how you could create an editor like Origami?
                      With KZNodes you can do that in a manner of minutes.
                       DESC
  s.homepage         = "https://github.com/krzysztofzablocki/KZNodes"
  s.license          = 'MIT'
  s.author           = { "Krzysztof Zablocki" => "krzysztof.zablocki@me.com" }
  s.source           = { :git => "https://github.com/krzysztofzablocki/KZNodes.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/merowing_'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*.h', 'Pod/Classes/**/*.m'
  s.resources = ['Pod/Assets/*']
end
