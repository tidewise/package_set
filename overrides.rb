Autoproj.manifest.each_autobuild_package do |pkg|
    if pkg.kind_of?(Autobuild::Orogen) && pkg.name != "tools/logger" && pkg.name != "base/orogen/types"
        pkg.optional_dependency 'tools/logger'
    end
end
