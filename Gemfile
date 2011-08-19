# Use `bundle install` in order to install these gems
# Use `bundle exec rake` in order to run the specs using the bundle
source "http://rubygems.org"
gemspec

group :test do
  gem 'pry'
  gem 'rake'
  gem 'shoulda','~> 2.11'
  gem 'mocha'
end

group :mongo do
	gem "bson", "1.2.0"
	gem "bson_ext", "1.2.0"
	gem "mongo", "1.2.0"
end

group :mongo_async do
	gem "bson", "1.2.0"
	gem "bson_ext", "1.2.0"
	gem "eventmachine", ">= 1.0.0.beta.3"
	gem "em-mongo", :git => "https://github.com/PlasticLizard/em-mongo.git"
	gem "em-synchrony", :git => "https://github.com/PlasticLizard/em-synchrony.git"
end

