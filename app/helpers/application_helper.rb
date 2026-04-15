module ApplicationHelper
  def adjuster_display_name(adjuster)
    return "—" if adjuster.nil?

    first = adjuster.profile&.first_name.presence
    last  = adjuster.profile&.last_name.presence
    if first || last
      [first, last].compact.join(" ")
    else
      adjuster.email
    end
  end
end
