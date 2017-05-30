module Rock
    def self.has_cxx11_support?(os_package_resolver)
        os_package_resolver.has?('libclang-castxml') || os_package_resolver.has?('castxml')
    end

    def self.default_loader_is_castxml?(os_package_resolver)
        os_package_resolver.has?('default_castxml')
    end

    # Offer the C++11 option only on systems where we either can install castxml
    # from the OS packages, or build it.
    #
    # But then, set it to true on OSes where it should. This is controlled by
    # stub osdep entries in defaults.osdeps
    def self.setup_cxx11_support(os_package_resolver, config)
        has_cxx11_support = has_cxx11_support?(os_package_resolver)
        if has_cxx11_support
            config.declare 'cxx11', 'boolean',
                default: 'no',
                doc: "whether C++11 should be enabled for Rock packages"
            cxx11_enabled = config.get('cxx11')
        else
            config.set 'cxx11', false
            cxx11_enabled = false
        end

        if !config.has_value_for?('typelib_cxx_loader')
            if cxx11_enabled
                config.set 'typelib_cxx_loader', 'castxml'
            elsif has_cxx11_support && default_loader_is_castxml?(os_package_resolver)
                config.set 'typelib_cxx_loader', 'castxml', true
            else
                config.set 'typelib_cxx_loader', 'gccxml'
            end
        end
    end
end

