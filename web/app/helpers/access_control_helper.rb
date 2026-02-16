module AccessControlHelper
  def can_view_details?(resource = nil)
    return false unless current_user
    return true if current_user.admin?
    return true if current_user.paid?
    return true if resource && current_user.owner_of_review?(resource)
    false
  end
end
