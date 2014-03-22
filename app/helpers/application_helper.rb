module ApplicationHelper

  #
  # Used in Jbuilder templates to build hyperlinks
  #
  def hyperlinks(links={})
    result = {}
    links.each do |qi, val|
      result[qi.to_s] = { 
                 "href" => val.kind_of?(String) ? val : val[:href], 
                 "type" => val.kind_of?(String) ? "application/json" : val[:type]
              }
    end
    result
  end
  

  #
  # This is needed everywhere except inside the Auth service to render creator
  # and updater links correctly.
  #
  def api_user_url(x)
    if x.blank?
      "#{OCEAN_API_URL}/#{Api.version_for :api_user}/api_users/0"
    elsif x.is_a?(Integer)
      "#{OCEAN_API_URL}/#{Api.version_for :api_user}/api_users/#{x}"
    elsif x.is_a?(String)
      x
    else
      raise "api_user_url takes an integer, a string, or nil"
    end
  end

end
