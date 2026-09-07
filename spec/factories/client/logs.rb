FactoryBot.define do
  factory :log_client, class: "Client::Log" do
    message { "Unhandled exception: ReferenceError" }
    severity { "error" }
    platform { "web" }
    environment { "development" }
  end
end
