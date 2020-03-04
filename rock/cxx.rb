module Rock
    def self.default_loader_is_castxml?(os_package_resolver)
        if defined? Autoproj::OSPackageResolver
            resolver = Autoproj::OSPackageResolver.load(
                File.join(__dir__, 'cxx.defaults'),
                operating_system: os_package_resolver.operating_system,
                package_managers: os_package_resolver.package_managers,
                os_package_manager: os_package_resolver.os_package_manager)
        else
            resolver = Autoproj::OSDependencies.load(File.join(__dir__, 'cxx.defaults'))
        end

        resolver.has?('default_castxml')
    end

    # Offer the C++11 option only on systems where we either can install castxml
    # from the OS packages, or build it.
    #
    # But then, set it to true on OSes where it should. This is controlled by
    # stub osdep entries in defaults.osdeps
    def self.setup_cxx_support(os_package_resolver, config)
        if !config.has_value_for?('typelib_cxx_loader')
            if default_loader_is_castxml?(os_package_resolver)
                config.set 'typelib_cxx_loader', 'castxml'
            else
                config.set 'typelib_cxx_loader', 'gccxml'
            end
        end
    end
end

