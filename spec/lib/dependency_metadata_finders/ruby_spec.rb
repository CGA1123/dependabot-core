# frozen_string_literal: true
require "octokit"
require "spec_helper"
require "bump/dependency"
require "bump/dependency_metadata_finders/ruby"

RSpec.describe Bump::DependencyMetadataFinders::Ruby do
  let(:dependency) do
    Bump::Dependency.new(
      name: dependency_name,
      version: "1.0",
      language: "ruby"
    )
  end
  subject(:finder) do
    described_class.new(dependency: dependency, github_client: github_client)
  end
  let(:github_client) { Octokit::Client.new(access_token: "token") }
  let(:dependency_name) { "business" }

  describe "#github_repo" do
    subject(:github_repo) { finder.github_repo }
    let(:rubygems_url) { "https://rubygems.org/api/v1/gems/business.json" }

    before do
      stub_request(:get, rubygems_url).
        to_return(status: 200, body: rubygems_response)
    end

    context "when there is a github link in the rubygems response" do
      let(:rubygems_response) { fixture("rubygems_response.json") }

      it { is_expected.to eq("gocardless/business") }

      it "caches the call to rubygems" do
        2.times { github_repo }
        expect(WebMock).to have_requested(:get, rubygems_url).once
      end

      context "that contains a .git suffix" do
        let(:rubygems_response) do
          fixture("rubygems_response_period_github.json")
        end

        it { is_expected.to eq("gocardless/business.rb") }
      end
    end

    context "when there isn't github link in the rubygems response" do
      let(:rubygems_response) { fixture("rubygems_response_no_github.json") }

      it { is_expected.to be_nil }

      it "caches the call to rubygems" do
        2.times { github_repo }
        expect(WebMock).to have_requested(:get, rubygems_url).once
      end
    end
  end
end
