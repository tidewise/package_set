module Rock
    # Context object used to evaluate the blocks given to in_flavor and only_in_flavor
    class InFlavorContext < BasicObject
        # @return [String] the name of the currently selected flavor
        attr_reader :current_flavor_name
        # @return [Array<String>] the set of flavors the context is made of
        #   (e.g. the flavors given to the in_flavor method)
        attr_reader :flavors
        # @return [Boolean] whether the package definitions present in the block
        #   should always be processed (false), or if they should be processed
        #   only if the current flavor is included in {flavors} (true)
        attr_reader :strict

        def initialize(current_flavor_name, flavors, strict)
            @current_flavor_name, @flavors, @strict =
                current_flavor_name, flavors, strict
        end

        def method_missing(m, *args, &block)
            # We only pass the *_package method calls
            if m.to_s =~ /^\w+_package$/
                package_name = args.first

                package_set = ::Autoproj.manifest.
                    definition_source(package_name) || ::Autoproj.current_package_set
                vcs = ::Autoproj.manifest.importer_definition_for(package_name, package_set)
                if (!vcs)
                    ::Kernel.raise ::ArgumentError, "#{package_name} has no version control definition in #{::File.join(package_set.local_dir, 'source.yml')}"
                end

                branch_is_flavor = ::TOPLEVEL_BINDING.instance_eval do
                    vcs.options[:branch] && flavor_defined?(vcs.options[:branch])
                end

                if branch_is_flavor
                    flavor_name = vcs.options[:branch]
                else flavor_name = current_flavor_name
                end

                if !strict || flavors.include?(flavor_name)
                    if block
                        ::TOPLEVEL_BINDING.instance_eval do
                            send(m, *args) do |pkg|
                                # We need to rebind the block into the toplevel binding so
                                # that toplevel methods used there get defined (again)
                                ::TOPLEVEL_BINDING.instance_exec(pkg, &block)
                            end
                        end
                    else
                        ::TOPLEVEL_BINDING.instance_eval do
                            send(m, *args)
                        end
                    end
                end
            elsif strict
                ::Kernel.raise ::ArgumentError, "only calls to the package definition methods are allows in only_in_flavor (found #{m})"
            else
                ::TOPLEVEL_BINDING.instance_eval do
                    send(m, *args, &block)
                end
            end
        end
    end
end

