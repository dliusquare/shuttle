# Copyright 2014 Square Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

require 'rails_helper'

RSpec.describe Section do
  before(:each) { allow_any_instance_of(Article).to receive(:import!) } # prevent auto-imports

  context "[validations]" do
    it "doesn't allow duplicate names in the scope of an Article" do
      article = FactoryBot.create(:article)
      section1 = FactoryBot.create(:section, name: "test", article: article)
      section2 = FactoryBot.build(:section, name: "test", article: article).tap(&:save)
      expect(section1).to be_persisted
      expect(section2).to_not be_persisted
    end
  end

  context "[scopes]" do
    describe "#active" do
      it "returns only active sections" do
        active_sections   = 2.times.map { FactoryBot.create(:section, active: true) }
        inactive_sections = 2.times.map { FactoryBot.create(:section, active: false) }
        expect(Section.active).to match_array(active_sections)
      end
    end
  end

  describe "#active_translations" do
    it "returns section's translations that are active, ie. key's index_in_section is not null" do
      section = FactoryBot.create(:section)
      key1 = FactoryBot.create(:key, project: section.project, section: section, index_in_section: 0)
      key2 = FactoryBot.create(:key, project: section.project, section: section, index_in_section: 1)
      key3 = FactoryBot.create(:key, project: section.project, section: section, index_in_section: nil)
      translation1 = FactoryBot.create(:translation, key: key1)
      translation2 = FactoryBot.create(:translation, key: key2)
      translation3 = FactoryBot.create(:translation, key: key3)

      expect(section.active_translations).to match_array([translation1, translation2])
    end
  end

  describe "#active_keys" do
    it "returns section's keys that are active, ie. index_in_section is not null" do
      section = FactoryBot.create(:section)
      key1 = FactoryBot.create(:key, project: section.project, section: section, index_in_section: 0)
      key2 = FactoryBot.create(:key, project: section.project, section: section, index_in_section: 1)
      FactoryBot.create(:key, project: section.project, section: section, index_in_section: nil)
      expect(section.active_keys).to match_array([key1, key2])
    end
  end

  describe "#sorted_active_keys_with_translations" do
    it "returns section's active keys ordered by index_in_section" do
      section = FactoryBot.create(:section)
      key1 = FactoryBot.create(:key, project: section.project, section: section, index_in_section: 0)
      key3 = FactoryBot.create(:key, project: section.project, section: section, index_in_section: 2) # create in non-sequential order
      key2 = FactoryBot.create(:key, project: section.project, section: section, index_in_section: 1)
      FactoryBot.create(:key, project: section.project, section: section, index_in_section: nil)

      keys = section.sorted_active_keys_with_translations.to_a
      expect(keys).to eql([key1, key2, key3])
      expect(keys.all? { |key| key.translations.loaded? }).to be_truthy
    end
  end
end
