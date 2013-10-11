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

require 'autoproj/gitorious'
if !Autoproj.has_source_handler? 'gitorious'
    Autoproj.gitorious_server_configuration('GITORIOUS', 'gitorious.org')
end
if !Autoproj.has_source_handler? 'github'
    Autoproj.gitorious_server_configuration('GITHUB', 'github.com')
end

FLAVORS = Hash.new
FLAVORED_PACKAGE_SETS = Set.new

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

    flavor = (FLAVORS[flavor_name] ||= FlavorDefinition.new(flavor_name))
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
    :possible_values => FLAVORS.keys,
    :doc => [
        "Which flavor of Rock do you want to use ?",
        "The 'stable' flavor is not updated often, but will contain well-tested code",
        "The 'next' flavor is updated more often, and might contain less tested code",
        "it is updated from 'master' to test new features before they get pushed in 'stable'",
        "Finally, 'master' is where the development takes place. It should generally be in",
        "a good state, but will break every once in a while",
        "",
        "See http://rock-robotics.org/startup/releases.html for more information"])


if ENV['ROCK_FORCE_FLAVOR']
    Autoproj.change_option('ROCK_FLAVOR', ENV['ROCK_FORCE_FLAVOR'])
end

def enabled_flavor_system
    FLAVORED_PACKAGE_SETS << Autoproj.current_package_set.name
end

if !defined? BasicObject
    BasicObject = Object
end

class InFlavorContext < BasicObject
    attr_reader :current_flavor_name, :flavors, :strict
    def initialize(current_flavor_name, flavors, strict)
        @current_flavor_name, @flavors, @strict =
            current_flavor_name, flavors, strict
    end

    def method_missing(m, *args, &block)
        # We only pass the *_package method calls
        if m.to_s =~ /^\w+_package$/
            package_name = args.first

            package_set = ::Autoproj.manifest.
                definition_source(package_name) || ::Autoproj.current_package_set
            vcs = ::Autoproj.manifest.importer_definition_for(package_name, package_set)

            if !vcs
                ::Kernel.puts [m, args.inspect]
            end
            branch_is_flavor = ::TOPLEVEL_BINDING.instance_eval do
                vcs.options[:branch] && flavor_defined?(vcs.options[:branch])
            end

            if branch_is_flavor
                flavor_name = vcs.options[:branch]
            else flavor_name = current_flavor_name
            end

            if !strict || flavors.include?(flavor_name)
                ::TOPLEVEL_BINDING.instance_eval do
                    send(m, *args, &block)
                end
            end
        else
            ::TOPLEVEL_BINDING.instance_eval do
                send(m, *args, &block)
            end
        end
    end
end

def in_flavor(*flavors, &block)
    if flavors.last.kind_of?(Hash)
        options = flavors.pop
        options = Kernel.validate_options options, :strict => false
    else
        options = Hash.new
    end

    flavor = FLAVORS[Autoproj.user_config('ROCK_FLAVOR')]
    if !flavor
        raise ArgumentError, "flavor #{flavor} is not defined"
    end

    current_packages = Autoproj.manifest.packages.keys
    InFlavorContext.new(flavor.name, flavors, options[:strict]).instance_eval(&block)
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

def flavor_defined?(flavor_name)
    FLAVORS.has_key?(flavor_name.to_s)
end

def package_in_flavor?(pkg, flavor_name)
    flavor_def = FLAVORS[flavor_name]
    if !flavor_def
        raise ArgumentError, "#{flavor_name} is not a known flavor name"
    end
    
    if pkg.respond_to?(:name)
	pkg = pkg.name
    end

    if flavor_def.implicit?
	pkg_set = Autoproj.manifest.definition_source(pkg)
	if FLAVORED_PACKAGE_SETS.include?(pkg_set.name)
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
            if !FLAVORS[flavor_name]
                raise ArgumentError, "#{flavor_name} is not a known flavor"
            end
            FLAVORS[flavor_name].removed_packages -= packages.to_set
            FLAVORS[flavor_name].default_packages[Autoproj.current_package_set.name] |= packages.to_set
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
            if !FLAVORS[flavor_name]
                raise ArgumentError, "#{flavor_name} is not a known flavor"
            end
	    FLAVORS[flavor_name].removed_packages |= packages.to_set
        end
    end
end

# Defines a bundle package in the installation
#
# So far, bundles are mostly Ruby packages
def bundle_package(*args, &block)
    ruby_package(*args) do |pkg|
        Autoproj.env_add_path 'ROCK_BUNDLE_PATH', pkg.srcdir
        pkg.instance_eval(&block)
    end
end

def bundle_package(name, &block)
    ruby_package(name, &block)
end

