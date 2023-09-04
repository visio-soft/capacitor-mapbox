require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'CapacitorMapboxNavigation'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['repository']['url']
  s.author = package['author']
  s.source = { :git => package['repository']['url'], :tag => s.version.to_s }
  s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.resources = 'ios/Plugin/**/*.{xib}'
  s.ios.deployment_target  = '13.0'
  s.static_framework = true
  s.dependency 'Capacitor'
  s.dependency 'MapboxNavigation'
  s.swift_version = '5.1'
end
