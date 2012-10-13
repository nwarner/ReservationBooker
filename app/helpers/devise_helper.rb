module DeviseHelper
  def devise_error_messages!  # is only called when trying to reset password
    flash[:alert] = "There was a problem sending your reset password instructions. Your " + resource.errors.full_messages[0].downcase + "." if not resource.errors.full_messages.empty?
    return ""
  end
end