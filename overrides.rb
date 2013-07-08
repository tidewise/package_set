# Migration from old-style .h base/types package to Rock-standard Bla.hpp
# package
base_types = package('base/types')
base_types.post_import do
    if File.file?(File.join(base_types.srcdir, 'base', 'Time.hpp'))
        includedir = File.join(base_types.prefix, 'include', 'base')
        if File.file?(File.join(includedir, 'time.h'))
            Autoproj.warn "deleting #{includedir} because of change in include structure"
            FileUtils.rm_rf includedir
            FileUtils.rm_rf base_types.installstamp
        end
    end
end

flavor = Autoproj.user_config('ROCK_FLAVOR')

if flv = @flavors[flavor]
    @flavored_package_sets.each do |pkg_set|
        meta = Autoproj.manifest.metapackages[pkg_set]
	if flv.implicit?
            in_a_flavor = @flavors.inject(Set.new) { |pkgs, (_, other_flavor)| pkgs | other_flavor.default_packages[pkg_set] }
	    default_packages = (meta.packages.map(&:name).to_set - in_a_flavor) |
		flv.default_packages[pkg_set]
	else
	    default_packages = flv.default_packages[pkg_set]
	end
	default_packages -= flv.removed_packages
        default_packages = default_packages.to_set
        flv.default_packages[pkg_set] = default_packages
        meta.packages.delete_if do |pkg|
            !default_packages.include?(pkg.name)
        end
    end
end

# If a package is using the 'next' or 'stable' branches, but the package is
# not enabled in the next or stable flavors, switch it back to master
switched_packages = []
wrong_branch = []
Autoproj.manifest.each_package_definition do |pkg_def|
    pkg = pkg_def.autobuild
    next if !pkg.importer.kind_of?(Autobuild::Git)
    if pkg.importer.branch == "next" || pkg.importer.branch == "stable"
        if !package_in_flavor?(pkg, pkg.importer.branch)
            vcs_raw = pkg_def.vcs.raw.reverse.find { |pkg_set_name, options| options['branch'] }
            if !vcs_raw || vcs_raw[1]['branch'] !~ /ROCK_FLAVOR/
                switched_packages << pkg
            end
            pkg.importer.branch = "master"
        end
    end

    if package_in_flavor?(pkg, flavor) && pkg.importer.branch != flavor
        wrong_branch << pkg
    end
end

if !switched_packages.empty?
    pkgs = switched_packages.map(&:name).sort.join(", ")

    Autoproj.warn ""
    Autoproj.warn "the following packages are using a branch which is incompatible with the flavors"
    Autoproj.warn "they are included in (as e.g. using the 'next' branch while being included only on 'master')."
    Autoproj.warn "they got switched back to master"
    Autoproj.warn "  #{pkgs}"
end

wrong_branch -= switched_packages
if !wrong_branch.empty?
    pkgs = wrong_branch.map { |pkg| "#{pkg.name}(#{pkg.importer.branch})" }.join(", ")

    Autoproj.warn ""
    Autoproj.warn "the following packages are using a different branch than the current flavor"
    Autoproj.warn "it is assumed that it is intentional"
    Autoproj.warn "  #{pkgs}"
end

if Autoproj.respond_to?(:post_import)
    # Override the CMAKE_BUILD_TYPE configuration parameter based on the
    # "stable" tag
    Autoproj.post_import do |pkg|
        next if !pkg.kind_of?(Autobuild::CMake)

        if !pkg.defines.has_key?('CMAKE_BUILD_TYPE')
            if pkg.has_tag?('stable')
                pkg.define "CMAKE_BUILD_TYPE", "Release"
            elsif pkg.has_tag?('needs_opt')
                pkg.define "CMAKE_BUILD_TYPE", "RelWithDebInfo"
            else
                pkg.define "CMAKE_BUILD_TYPE", "Debug"
            end
        end
    end

    # If a package is on next or stable, make sure that one cannot add new
    # commits without knowing what he is doing
    Autoproj.post_import do |pkg|
        next if !pkg.importer.kind_of?(Autobuild::Git)

        hook_source_path = File.join(File.expand_path(File.dirname(__FILE__)), "git_do_not_commit_hook")
        hook_dest_path   = File.join(pkg.srcdir, '.git', 'hooks', 'pre-commit')
        if File.directory?(File.dirname(hook_dest_path))
            if pkg.importer.branch == "next" || pkg.importer.branch == "stable"
                # Install do-not-commit hook
                FileUtils.cp hook_source_path, hook_dest_path
            else
                # Remove the do-not-commit hook
                FileUtils.rm_f hook_dest_path
            end
        end
    end
end

Autoproj.env_add_path 'ROCK_BUNDLE_PATH', File.join(Autobuild.prefix, 'share', 'rock')
Autoproj.env_add_path 'ROCK_BUNDLE_PATH', File.join(Autoproj.root_dir, 'bundles')

# Finally, verify that when pkg A from flavor X depends on pkg B, then B needs
# to be available in flavor X as well
Autoproj.post_import do |pkg|
    next if !pkg.importer.kind_of?(Autobuild::Git)

    if (flv = @flavors[pkg.importer.branch]) && flv.include?(pkg.name)
        #Skip packages that are only on master, because packages for 'master' 
        #are not automaticly added to the master flavor. So the check would fail
        next if flv.name == 'master' 

        pkg.dependencies.each do |dep_name|
            #Check only for packages that are Git's too if they are in the same flavor availible
            if !flv.include?(dep_name) && Autoproj.manifest.package(dep_name).autobuild.importer.kind_of?(Autobuild::Git)
                raise ConfigError, "#{pkg.name}, in flavor #{flv.name}, depends on #{dep_name} which is not included in this flavor"
            end
        end
    end
end

