$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "notification_service/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "notification_service"
  spec.version     = NotificationService::VERSION
  spec.authors     = ["Arman"]
  spec.email       = ["arman.sarrafi@customerservice.nsw.gov.au"]
  spec.homepage    = ""
  spec.summary     = "Summary of NotificationService."
  spec.description = "Description of NotificationService."
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
end
