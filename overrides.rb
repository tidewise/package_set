flavor = Autoproj.user_config('ROCK_FLAVOR')

if flv = @flavors[flavor]
    @flavored_package_sets.each do |pkg_set|
        meta = Autoproj.manifest.metapackages[pkg_set]
	if flv.implicit?
	    default_packages = meta.packages.map(&:name).to_set |
		flv.default_packages[pkg_set]
	else
	    default_packages = flv.default_packages[pkg_set]
	end
	default_packages -= flv.removed_packages
        meta.packages.clear
        Autoproj.manifest.metapackage(pkg_set, *(default_packages.to_a))
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
        if File.directory?(hook_dest_path)
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

