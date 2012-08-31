module DeviseHelper
  # is only called when trying to reset password
  def devise_error_messages!
    flash[:error] = "There was a problem sending your reset password instructions. Your " + resource.errors.full_messages[0].downcase + "." if not resource.errors.full_messages.empty?
    return ""
  end
end