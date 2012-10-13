module ApplicationHelper
  def full_title(page_title) # returns the full title on a per-page basis.
    base_title = "Reservation Booker"
    if page_title.empty?
      base_title
    else
      "#{base_title} | #{page_title}"
    end
  end
end
