# coding: UTF-8
Before do
  include Milieu
  Family.destroy_all
  family = FactoryGirl.build :family
  FactoryGirl.create :taxon_state, taxon_id: family.id
  family.save!
  $Milieu = RestrictedMilieu.new
end

Before('@preview') do
  $Milieu = SandboxMilieu.new :preview
end

After('@preview') do
  $Milieu = RestrictedMilieu.new
end

After {Sunspot.remove_all!}
