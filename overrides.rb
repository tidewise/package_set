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

current_flavor = Rock.flavors.current_flavor

Rock.flavors.finalize
switched_packages = Rock.flavors.reset_invalid_branches_to('master')
wrong_branch = Rock.flavors.find_all_overriden_flavored_branches

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

require File.join(File.dirname(__FILE__), 'rock/git_hook')
require File.join(File.dirname(__FILE__), 'rock/cmake_build_type')
Autoproj.post_import do |pkg|
    if pkg.kind_of?(Autobuild::CMake)
        Rock.update_cmake_build_type_from_tags(pkg)
    end
    if pkg.importer.kind_of?(Autobuild::Git)
        if pkg.importer.branch == "next" || pkg.importer.branch == "stable"
            Rock.install_git_hook pkg, 'git_do_not_commit_hook', 'pre-commit'
        else
            Rock.remove_git_hook pkg, 'pre-commit'
        end
    end
end

Autoproj.env_add_path 'ROCK_BUNDLE_PATH', File.join(Autobuild.prefix, 'share', 'rock')
Autoproj.env_add_path 'ROCK_BUNDLE_PATH', File.join(Autoproj.root_dir, 'bundles')

# Finally, verify that when pkg A from flavor X depends on pkg B, then B needs
# to be available in flavor X as well
if ENV['ROCK_DISABLE_CROSS_FLAVOR_CHECKS'] != '1'
    Autoproj.post_import do |pkg|
        next if !pkg.importer.kind_of?(Autobuild::Git)
        Rock.flavors.verify_cross_flavor_dependencies(pkg)
    end
end

