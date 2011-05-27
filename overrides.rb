# We want to avoid accidents where stuff gets pushed to next or stable that was
# not intended to be there
#
# We therefore set the push_to_branch to master. This makes sure that
#
#   git push
#   git push autobuild
#
# pushes to master instead of the local branch
Autoproj.manifest.each_package do |pkg|
    if pkg.importer.kind_of?(Autobuild::Git)
        if !pkg.importer.push_to_branch
            if pkg.importer.branch == "next" || pkg.importer.branch == "stable"
                pkg.importer.push_to_branch = "master"
            else
                pkg.importer.push_to_branch = pkg.importer.branch
            end
        end
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
end

