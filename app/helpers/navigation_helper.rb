module NavigationHelper
  def active_nav_classes(path)
    if current_page?(path)
      "bg-blue-50 text-blue-700"
    else
      "text-gray-700 hover:bg-gray-100"
    end
  end
end
