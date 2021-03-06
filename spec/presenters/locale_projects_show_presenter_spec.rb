# Copyright 2014 Square Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicabcle law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

require 'rails_helper'

RSpec.describe LocaleProjectsShowPresenter do
  before :each do
    allow_any_instance_of(Article).to receive(:import!) # prevent auto imports
    @user = FactoryBot.create(:user)
  end

  describe "#selectable_commits" do
    it "returns selectable Commits" do
      project = FactoryBot.create(:project)

      commit1 = FactoryBot.create(:commit, revision: 'abcd', message: "hello", project: project)
      commit2 = FactoryBot.create(:commit, revision: '1234', message: "world", project: project)

      presenter = LocaleProjectsShowPresenter.new(project, @user, {})
      expect(presenter.selectable_commits).to eql( [["ALL COMMITS", nil], ["1234: world", "1234"], ["abcd: hello", "abcd"]] )
    end
  end

  describe "#selected_commit" do
    it "returns the selected Commit if there is one" do
      commit = FactoryBot.create(:commit, revision: 'abcd')
      presenter = LocaleProjectsShowPresenter.new(commit.project, @user, {commit: 'abcd'})
      expect(presenter.selected_commit).to eql(commit)
    end
  end

  describe "#selected_article" do
    it "returns the selected Article if there is one" do
      article = FactoryBot.create(:article, name: 'abcd')
      presenter = LocaleProjectsShowPresenter.new(article.project, @user, { article_id: article.id })
      expect(presenter.selected_article).to eql(article)
    end
  end

  describe "#selectable_sections" do
    before :each do
      @project = FactoryBot.create(:project)
      @article1 = FactoryBot.create(:article, name: 'article1', project: @project)
      @section1 = FactoryBot.create(:section, name: 'section1', article: @article1)
      @article2 = FactoryBot.create(:article, name: 'article2', project: @project)
      @section2 = FactoryBot.create(:section, name: 'section2', article: @article2)
    end

    it "returns selectable Sections under the Article if an Article is selected" do
      presenter = LocaleProjectsShowPresenter.new(@project, @user, { article_id: @article1.id })
      expect(presenter.selectable_sections).to eql( [["ALL SECTIONS", nil], ["section1", @section1.id]] )
    end

    it "returns selectable Sections under the Project if an Article is NOT selected" do
      presenter = LocaleProjectsShowPresenter.new(@project, @user, { })
      expect(presenter.selectable_sections).to match_array( [["ALL SECTIONS", nil], ["section1", @section1.id], ["section2", @section2.id]])
    end

    it "doesn't include inactive Sections in the result" do
      @section1.update_columns active: false
      presenter = LocaleProjectsShowPresenter.new(@project, @user, { })
      expect(presenter.selectable_sections).to eql( [["ALL SECTIONS", nil], ["section2", @section2.id]] )
    end
  end

  describe "#selected_section" do
    before :each do
      @project = FactoryBot.create(:project)
      @article1 = FactoryBot.create(:article, name: 'article1', project: @project)
      @section1 = FactoryBot.create(:section, name: 'section1', article: @article1)
      @article2 = FactoryBot.create(:article, name: 'article2', project: @project)
      @section2 = FactoryBot.create(:section, name: 'section2', article: @article2, active: false)
    end

    it "returns selected Section" do
      presenter = LocaleProjectsShowPresenter.new(@project, @user, { section_id: @section1.id })
      expect(presenter.selected_section).to eql( @section1 )
    end

    it "doesn't return inactive Section even if user attempted to select it" do
      presenter = LocaleProjectsShowPresenter.new(@project, @user, { section_id: @section2.id })
      expect(presenter.selected_section).to be_nil
    end
  end
end
