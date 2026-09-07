# app/constants/app_version_constants.rb

module AppVersionConstants
  module Status
    DRAFT     = "draft".freeze
    PUBLISHED = "published".freeze
    YANKED    = "yanked".freeze
    ALL       = [ DRAFT, PUBLISHED, YANKED ].freeze
  end

  module Number
    FORMAT = /\A\d+\.\d+\.\d+\z/.freeze
  end
end
