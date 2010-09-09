# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{wonkavision}
  s.version = "0.5.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nathan Stults"]
  s.date = %q{2010-09-09}
  s.description = %q{Wonkavision is a small gem that allows you to publish}
  s.email = %q{hereiam@sonic.net}
  s.extra_rdoc_files = [
    "LICENSE.txt",
     "README.rdoc"
  ]
  s.files = [
    "CHANGELOG.rdoc",
     "LICENSE.txt",
     "README.rdoc",
     "Rakefile",
     "lib/wonkavision.rb",
     "lib/wonkavision/acts_as_oompa_loompa.rb",
     "lib/wonkavision/event.rb",
     "lib/wonkavision/event_binding.rb",
     "lib/wonkavision/event_context.rb",
     "lib/wonkavision/event_coordinator.rb",
     "lib/wonkavision/event_handler.rb",
     "lib/wonkavision/event_namespace.rb",
     "lib/wonkavision/event_path_segment.rb",
     "lib/wonkavision/message_mapper.rb",
     "lib/wonkavision/message_mapper/indifferent_access.rb",
     "lib/wonkavision/message_mapper/map.rb",
     "lib/wonkavision/persistence/mongo_mapper_adapter.rb",
     "lib/wonkavision/plugins.rb",
     "lib/wonkavision/plugins/business_activity.rb",
     "lib/wonkavision/plugins/business_activity/event_binding.rb",
     "lib/wonkavision/plugins/callbacks.rb",
     "lib/wonkavision/plugins/event_handling.rb",
     "lib/wonkavision/plugins/timeline.rb",
     "lib/wonkavision/support.rb",
     "lib/wonkavision/version.rb",
     "test/business_activity_test.rb",
     "test/config/database.yml",
     "test/event_coordinator_test.rb",
     "test/event_handler_test.rb",
     "test/event_namespace_test.rb",
     "test/event_path_segment_test.rb",
     "test/event_test.rb",
     "test/log/test.log",
     "test/map_test.rb",
     "test/message_mapper_test.rb",
     "test/test_activity_models.rb",
     "test/test_helper.rb",
     "test/timeline_test.rb",
     "test/wonkavision_test.rb",
     "wonkavision.gemspec"
  ]
  s.homepage = %q{http://github.com/PlasticLizard/wonkavision}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Simple Business Activity Monitoring}
  s.test_files = [
    "test/business_activity_test.rb",
     "test/event_coordinator_test.rb",
     "test/event_handler_test.rb",
     "test/event_namespace_test.rb",
     "test/event_path_segment_test.rb",
     "test/event_test.rb",
     "test/map_test.rb",
     "test/message_mapper_test.rb",
     "test/test_activity_models.rb",
     "test/test_helper.rb",
     "test/timeline_test.rb",
     "test/wonkavision_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 2.3"])
      s.add_development_dependency(%q<shoulda>, ["= 2.10.3"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.3"])
      s.add_dependency(%q<shoulda>, ["= 2.10.3"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.3"])
    s.add_dependency(%q<shoulda>, ["= 2.10.3"])
  end
end

