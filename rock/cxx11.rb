module Rock
    # Offer the C++11 option only on systems where we either can install castxml
    # from the OS packages, or build it.
    #
    # But then, set it to true on OSes where it should. This is controlled by
    # stub osdep entries in defaults.osdeps
    def self.setup_cxx11_support(os_package_resolver, config)
        if os_package_resolver.has?('libclang-castxml') || os_package_resolver.has?('castxml')
            config.declare 'cxx11', 'boolean',
                default: 'no',
                doc: "whether C++11 should be enabled for Rock packages"
        else
            config.set 'typelib_cxx_loader', 'gccxml'
            config.set 'cxx11', false
        end

        if !config.has_value_for?('castxml') && os_package_resolver.has?('default_castxml')
            config.set 'typelib_cxx_loader', 'castxml', true
        end
        if !config.has_value_for?('cxx11') && os_package_resolver.has?('default_cxx11')
            config.set 'cxx11', true, true
        end

        # Trigger the choice for C++11 if there is one, and force castxml if it is the case
        if config.get('cxx11')
            config.set 'typelib_cxx_loader', 'castxml'
        else
            config.set 'typelib_cxx_loader', 'gccxml'
        end
    end
end

