module AccessControlHelper
  def can_view_details?(resource = nil)
    return false unless authenticated?
    return true if auth_service.meets_requirements?(:admin)
    return true if paid_subscriber?
    return true if resource&.respond_to?(:clerk_user_id) &&
                   resource.clerk_user_id == auth_service.user_id
    false
  end
end
