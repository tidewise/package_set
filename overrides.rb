flavor = Autoproj.user_config('ROCK_FLAVOR')

if @flavors[flavor] && !@flavors[flavor].implicit?
    default_sets = @flavors[flavor].default_packages
    default_sets.each do |pkg_set, packages|
        meta = Autoproj.manifest.metapackages[pkg_set]
        meta.packages.clear
        Autoproj.manifest.metapackage(pkg_set, *(packages.to_a))
    end
end

# If a package is using the 'next' or 'stable' branches, but the package is
# not enabled in the next or stable flavors, switch it back to master
switched_packages = []
Autoproj.manifest.each_package do |pkg|
    next if !pkg.importer.kind_of?(Autobuild::Git)
    if pkg.importer.branch == "next" || pkg.importer.branch == "stable"
        if !package_in_flavor?(pkg, pkg.importer.branch)
            switched_packages << pkg
            pkg.importer.branch = "master"

        end
    end
end

if !switched_packages.empty?
    pkgs = switched_packages.map(&:name).sort.join(", ")

    Autoproj.warn "the following packages are using a branch which is incompatible with the flavors"
    Autoproj.warn "they are included in (as e.g. using the 'next' branch while being included only on 'master')."
    Autoproj.warn "they got switched back to master"
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
        if pkg.importer.branch == "next" || pkg.importer.branch == "stable"
            # Install do-not-commit hook
            FileUtils.cp hook_source_path, hook_dest_path
        else
            # Remove the do-not-commit hook
            FileUtils.rm_f hook_dest_path
        end
    end
end

