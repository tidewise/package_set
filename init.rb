configuration_option 'DFKI_SHARE', 'string',
    :default => File.join(ENV['HOME'], "dfki-share"),
    :doc => "where the DFKI research folder is mounted" do |path|

    if path =~ /^\w+:\/\//
        # If it is an URL, do not validate
        path
    elsif File.directory?(File.join(path, "projects", "all"))
        path
    else
        raise InputError, "#{File.join(path, "projects", "all")} does not exist"
    end
end
