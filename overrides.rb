Autoproj.manifest.each_autobuild_package do |pkg|
    next if !pkg.kind_of?(Autobuild::Orogen)
    if pkg.name != "tools/logger" && pkg.name != "base/orogen/types"
        pkg.optional_dependency 'tools/logger'
    end
    pkg.optional_dependency 'tools/service_discovery'
    if !Autoproj.user_config('USE_OCL')
        pkg.optional_dependencies.delete 'ocl'
    end
end
