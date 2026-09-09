# app/models/iam/role_permission.rb:

module Iam
  class RolePermission < ApplicationRecord
    self.table_name = "iam_role_permissions"

    belongs_to :role, class_name: "Iam::Role"
    belongs_to :permission, class_name: "Iam::Permission"

    validates :role_id, uniqueness: { scope: :permission_id }

    before_update :prevent_super_admin_unassignment
    before_destroy :prevent_super_admin_unassignment

    private

    def prevent_super_admin_unassignment
      protected_role_id = role_id_in_database || role_id
      return unless Iam::Role.exists?(
        id: protected_role_id,
        name: IamConstants::Role::SUPER_ADMIN
      )

      errors.add(:base, "Permissions cannot be removed from the super admin role")
      throw(:abort)
    end
  end
end
