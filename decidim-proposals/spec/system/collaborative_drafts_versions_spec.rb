# frozen_string_literal: true

require "spec_helper"

describe "Explore versions", versioning: true, type: :system do
  include_context "with a component"
  let(:component) { create(:proposal_component, :with_creation_enabled, :with_collaborative_drafts_enabled, organization: organization) }

  let(:manifest_name) { "proposals" }
  let!(:author) { create :user, :confirmed, organization: organization }

  let(:collaborative_draft_path) do
    Decidim::ResourceLocatorPresenter.new(collaborative_draft).path
  end
  let(:original_title) { "The original title" }
  let(:edited_title) { "The edited title" }
  let(:original_body) { "Original body, consequuntur cupiditate non reprehenderit est vero fugiat" }
  let(:edited_body) { "Edited body, Rerum assumenda blanditiis voluptatum autem, praesentium necessitatibus est" }
  let!(:collaborative_draft) { create(:collaborative_draft, component: component, title: original_title, body: original_body) }

  before do
    Decidim.traceability.update!(
      collaborative_draft,
      author,
      title: edited_title,
      body: edited_body
    )
    visit collaborative_draft_path
  end

  context "when visiting versions index" do
    before do
      click_link "see other versions"
    end

    it "lists all versions" do
      expect(page).to have_link("Version 1")
      expect(page).to have_link("Version 2")
    end

    it "shows the versions count" do
      expect(page).to have_content("VERSIONS\n2")
    end

    it "allows going back to the result" do
      click_link "Go back to collaborative draft"
      expect(page).to have_current_path collaborative_draft_path
    end

    it "shows the version author and creation date" do
      within ".card--list__item:last-child" do
        expect(page).to have_content(author.name)
        expect(page).to have_content(Time.zone.today.strftime("%d/%m/%Y"))
      end
    end
  end

  context "when showing version" do
    before do
      click_link "see other versions"

      within ".card--list__item:last-child" do
        click_link("Version 2")
      end
    end

    it "shows the version number" do
      expect(page).to have_content("VERSION NUMBER\n2 out of 2")
    end

    it "allows going back to the collaborative draft" do
      click_link "Go back to collaborative draft"
      expect(page).to have_current_path collaborative_draft_path
    end

    it "allows going back to the versions list" do
      click_link "Show all versions"
      expect(page).to have_current_path collaborative_draft_path + "/versions"
    end

    it "shows the version author and creation date" do
      within ".card.extra.definition-data" do
        expect(page).to have_content(author.name)
        expect(page).to have_content(Time.zone.today.strftime("%d/%m/%Y"))
      end
    end

    it "shows the changed attributes" do
      expect(page).to have_content("Changes at")
      expect(page).to have_content("TITLE")
      expect(page).to have_content("BODY")

      first ".diff-string > .removal" do
        expect(page).to have_content(original_title)
      end
      first ".diff-string > .addition" do
        expect(page).to have_content(edited_title)
      end

      all(".diff-string > .removal").last do
        expect(page).to have_content(original_body)
      end
      all(".diff-string > .addition").last do
        expect(page).to have_content(edited_body)
      end
    end
  end
end
