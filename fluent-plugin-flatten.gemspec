Gem::Specification.new do |gem|
  gem.name          = 'fluent-plugin-flatten'
  gem.version       = '0.0.1'
  gem.authors       = ['Kentaro Kuribayashi']
  gem.email         = ['kentarok@gmail.com']
  gem.homepage      = 'http://github.com/kentaro/fluent-plugin-flatten'
  gem.description   = %q{Fluentd plugin to flatten JSON-formatted string values to top level key/value-s.}
  gem.summary       = %q{Fluentd plugin to flatten JSON-formatted string values to top level key/value-s.}

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'fluentd'
  gem.add_runtime_dependency     'fluentd'
end
