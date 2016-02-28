# We're having issues with production code enabling PaperTrail
# even when if it is globally disabled in the test env. Once enabled it
# stays enabled, which spills over into unrelated tests.
After do
  PaperTrail.enabled = false
end

# putting `require 'paper_trail/frameworks/cucumber'` inside support/env.rb and
#   config.after_initialize do
#     PaperTrail.enabled = false
#   end
# inside environments/test.rb is supposed to help, but it doesn't.
#
# Code for trying to find out what causes PaperTrail to become enabled.
# Uncomment if you enjoy colors and non-deterministic systems.
# Before do
#   if PaperTrail.enabled?
#     $stderr.puts "Before scenario: PaperTrail enabled".yellow
#   else
#     $stderr.puts "Before scenario: PaperTrail disabled".blue
#   end
# end
# AfterStep  do
#   if PaperTrail.enabled?
#     PaperTrail.enabled = false
#     $stderr.puts "After step: PaperTrail was enabled; disabled it".red
#   end
# end

Before "@papertrail" do
  PaperTrail.enabled = true
end

After "@papertrail" do
  PaperTrail.enabled = false
end

# Some drivers remembers the window size between tests, so always restore.
Before "@responsive" do
  resize_window_to_device :desktop
end

After "@responsive" do
  resize_window_to_device :desktop
end

# Temporary work-around.
# Basically:
#   In dev/prod: autohide taxon browser and close all except the last panel
#   In test: don't autohide, and open all panels (performance/test reasons)
#   In @taxon_browser tests: behave as in prod/dev
# Added in f3f10710011ad3b3ccdbc3059ffa000f8be8fbd3.
Before "@taxon_browser" do
  $taxon_browser_test_hack = true
end

After "@taxon_browser" do
  $taxon_browser_test_hack = false
end

# From http://makandracards.com/makandra/1709-single-step-and-
# slow-motion-for-cucumber-scenarios-using-javascript-selenium
# Use with `@javascript` and `DRIVER=selenium --format pretty` for the full experience.
Before '@slow_motion' do
  @slow_motion = true
end

After '@slow_motion' do
  @slow_motion = false
end

Transform /.*/ do |match|
  if @slow_motion
    sleep 1.5
  end
  match
end

AfterStep '@single_step' do
  print "Single Stepping. Hit enter to continue."
  STDIN.getc
end
