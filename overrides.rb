flavor = Autoproj.user_config('ROCK_FLAVOR')

if @flavors[flavor] && !@flavors[flavor].implicit?
    default_sets = @flavors[flavor].default_packages
    default_sets.each do |pkg_set, packages|
        meta = Autoproj.manifest.metapackages[pkg_set]
        meta.packages.clear
        Autoproj.manifest.metapackage(pkg_set, *(packages.to_a))
    end
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

