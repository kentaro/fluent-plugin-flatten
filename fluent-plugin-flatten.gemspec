Gem::Specification.new do |gem|
  gem.name          = 'fluent-plugin-flatten'
  gem.version       = '0.1.1'
  gem.authors       = ['Kentaro Kuribayashi']
  gem.email         = ['kentarok@gmail.com']
  gem.homepage      = 'http://github.com/kentaro/fluent-plugin-flatten'
  gem.description   = %q{Fluentd plugin to extract values for nested key paths and re-emit them as flat tag/record pairs.}
  gem.summary       = %q{Fluentd plugin to extract values for nested key paths and re-emit them as flat tag/record pairs.}
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'appraisal'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'test-unit', '~> 3.0'
  gem.add_runtime_dependency     'fluentd', ['>= 0.14.8', '< 2']
end
