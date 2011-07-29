#
# Orocos Specific ignore rules
#
# Ignore log files generated from the orocos/orogen components
ignore(/\.log$/, /\.ior$/, /\.idx$/)
# Ignore all text files except CMakeLists.txt
ignore(/(^|\/)(?!CMakeLists)[^\/]+\.txt$/)
# We don't care about the manifest being changed, as autoproj *will* take
# dependency changes into account
ignore(/manifest\.xml$/)
# Ignore vim swap files
ignore(/\.sw?$/)
# Ignore the numerous backup files
ignore(/~$/)
configuration_option 'ROCK_FLAVOR', 'string',
    :default => 'stable',
    :values => ['stable', 'next', 'master'],
    :doc => [
        "Which flavor of Rock do you want to use ?",
        "The 'stable' flavor is not updated often, but will contain well-tested code",
        "The 'next' flavor is updated more often, and might contain less tested code",
        "it is updated from 'master' to test new features before they get pushed in 'stable'",
        "Finally, 'master' is where the development takes place. It should generally be in",
        "a good state, but will break every once in a while",
        "",
        "See http://rock-robotics.org/startup/releases.html for more information"]

if ENV['ROCK_FORCE_FLAVOR']
    Autoproj.change_option('ROCK_FLAVOR', ENV['ROCK_FORCE_FLAVOR'])
end

def enable_next_stable_scheme
end

# Setup handling to override the list of default packages in next and stable
#
# The actual lists are created in overrides.rb
@default_packages = Hash.new
@default_packages['next'] = Hash.new { |h, k| h[k] = Set.new }
@default_packages['stable'] = Hash.new { |h, k| h[k] = Set.new }

def in_flavor(*flavors)
    flavor = Autoproj.user_config('ROCK_FLAVOR')
    current_packages = Autoproj.manifest.packages.keys
    yield if flavors.include?(flavor)
    new_packages = Autoproj.manifest.packages.keys - current_packages
    flavors.each do |flav|
        @default_packages[flav][Autoproj.current_package_set.name] |= new_packages.to_set
    end
end

def define_flavors(*names)
    names.each do |flavor_name|
        @default_packages[flavor_name] = Hash.new { |h, k| h[k] = Set.new }
    end
    enable_flavor_system
end

def enable_flavor_system
    @default_packages.each_value do |metapackages|
        metapackages[Autoproj.current_package_set.name]
    end
end

define_flavors 'next', 'stable'
