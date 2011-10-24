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

@flavors = Hash.new
@flavored_package_sets = Set.new

class FlavorDefinition
    attr_reader :name
    attr_accessor :includes
    attr_predicate :implicit?, true
    attr_accessor :default_packages
    attr_accessor :removed_packages

    def initialize(name)
        @name = name
        @includes = Set.new
        @implicit = false
        @default_packages = Hash.new { |h, k| h[k] = Set.new }
        @removed_packages = Set.new
    end

    def include?(package_name)
	return false if removed?(package_name)
        @default_packages.any? do |pkg_set, packages|
            packages.include?(package_name)
        end
    end

    def removed?(package_name)
	removed_packages.include?(package_name)
    end

    def enabled_in?(*flavors)
        (flavors.to_set - includes).size != flavors.size ||
            flavors.include?(name)
    end
end


def define_flavor(flavor_name, options = Hash.new)
    options = Kernel.validate_options(options, :includes => [], :implicit => nil)

    flavor = (@flavors[flavor_name] ||= FlavorDefinition.new(flavor_name))
    if !options[:implicit].nil?
        flavor.implicit = options[:implicit]
    end
    flavor.includes |= options[:includes]
end

define_flavor 'stable'
define_flavor 'next',  :includes => ['stable']
define_flavor 'master', :includes => ['stable', 'next'], :implicit => true

configuration_option('ROCK_FLAVOR', 'string',
    :default => 'stable',
    :values => @flavors.keys,
    :doc => [
        "Which flavor of Rock do you want to use ?",
        "The 'stable' flavor is not updated often, but will contain well-tested code",
        "The 'next' flavor is updated more often, and might contain less tested code",
        "it is updated from 'master' to test new features before they get pushed in 'stable'",
        "Finally, 'master' is where the development takes place. It should generally be in",
        "a good state, but will break every once in a while",
        "",
        "See http://rock-robotics.org/startup/releases.html for more information"]) do |value|

    value
end


if ENV['ROCK_FORCE_FLAVOR']
    Autoproj.change_option('ROCK_FLAVOR', ENV['ROCK_FORCE_FLAVOR'])
end

def enabled_flavor_system
    @flavored_package_sets << Autoproj.current_package_set.name
end

def in_flavor(*flavors)
    if flavors.last.kind_of?(Hash)
        options = flavors.pop
        options = Kernel.validate_options options, :strict => false
    else
        options = Hash.new
    end

    flavor = @flavors[Autoproj.user_config('ROCK_FLAVOR')]
    if !flavor
        raise ArgumentError, "flavor #{flavor} is not defined"
    end

    current_packages = Autoproj.manifest.packages.keys
    if !options[:strict] || flavor.enabled_in?(*flavors)
        yield 
    end
    new_packages = Autoproj.manifest.packages.keys - current_packages
    add_packages_to_flavors flavors => new_packages
end

def only_in_flavor(*flavors, &block)
    if flavors.last.kind_of?(Hash)
        options = flavors.pop
        options, other_options = Kernel.filter_options options, :strict => true
        options = options.merge(other_options)
    else
        options = { :strict => true }
    end
    flavors << options
    in_flavor(*flavors, &block)
end

def package_in_flavor?(pkg, flavor_name)
    flavor_def = @flavors[flavor_name]
    if !flavor_def
        raise ArgumentError, "#{flavor_name} is not a known flavor name"
    end
    
    if pkg.respond_to?(:name)
	pkg = pkg.name
    end

    if flavor_def.implicit?
	pkg_set = Autoproj.manifest.definition_source(pkg)
	if @flavored_package_sets.include?(pkg_set.name)
	    !flavor_def.removed?(pkg)
	else
	    flavor_def.include?(pkg)
	end
    else
        return flavor_def.include?(pkg)
    end
end

def add_packages_to_flavors(mappings)
    enabled_flavor_system
    mappings.each do |flavors, packages|
        if !flavors.respond_to?(:to_ary)
            flavors = [flavors]
        end
        if !packages.respond_to?(:to_ary)
            packages = [packages]
        end
        flavors.each do |flavor_name|
            if !@flavors[flavor_name]
                raise ArgumentError, "#{flavor_name} is not a known flavor"
            end
            @flavors[flavor_name].removed_packages -= packages.to_set
            @flavors[flavor_name].default_packages[Autoproj.current_package_set.name] |= packages.to_set
        end
    end
end

def remove_packages_from_flavors(mappings)
    enabled_flavor_system
    mappings.each do |flavors, packages|
        if !flavors.respond_to?(:to_ary)
            flavors = [flavors]
        end
        if !packages.respond_to?(:to_ary)
            packages = [packages]
        end
        flavors.each do |flavor_name|
            if !@flavors[flavor_name]
                raise ArgumentError, "#{flavor_name} is not a known flavor"
            end
	    @flavors[flavor_name].removed_packages |= packages.to_set
        end
    end
end

