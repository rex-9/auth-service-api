# frozen_string_literal: true

require "rails_helper"

RSpec.describe AnalyticsConstants do
  it "keeps the shared action_noun event contract stable" do
    expect(described_class::Event::ALL).to eq(%w[
      sign_up
      sign_in
      sign_out
      begin_onboarding
      complete_onboarding
      view_page
      view_product
      purchase_product
      open_notification
    ])
  end

  it "uses the shared purchase amount parameter" do
    expect(described_class::Parameter::UNIT_AMOUNT).to eq("unit_amount")
  end
end
