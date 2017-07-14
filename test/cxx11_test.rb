require 'test_helpers'
require 'rock/cxx11'

module Rock
    describe "setup_cxx11_support" do
        before do
            @config = Autoproj::Configuration.new
            flexmock(@config)
            flexmock(Rock)
        end

        if defined? Autoproj::OSPackageResolver
            describe "#default_loader_is_castxml?" do
                it "returns true if the entry for default_castxml is 'ignore' on this OS" do
                    resolver = flexmock(
                        operating_system: [['ubuntu'], ['16.04', 'default']],
                        package_managers: Autoproj::OSPackageResolver::PACKAGE_MANAGERS.dup,
                        os_package_manager: nil)
                    assert Rock.default_loader_is_castxml?(resolver)
                end

                it "returns false if the entry for default_castxml is 'nonexistent' on this OS" do
                    resolver = flexmock(
                        operating_system: [['ubuntu'], ['14.04', 'default']],
                        package_managers: Autoproj::OSPackageResolver::PACKAGE_MANAGERS.dup,
                        os_package_manager: nil)
                    refute Rock.default_loader_is_castxml?(resolver)
                end
            end
        else
            describe "#default_loader_is_castxml?" do
                before do
                    @current_os = Autoproj::OSDependencies.operating_system
                end
                after do
                    Autoproj::OSDependencies.operating_system = @current_os
                end

                it "returns true if the entry for default_castxml is 'ignore' on this OS" do
                    Autoproj::OSDependencies.operating_system = [['ubuntu'], ['16.04', 'default']]
                    assert Rock.default_loader_is_castxml?(flexmock)
                end

                it "returns false if the entry for default_castxml is 'nonexistent' on this OS" do
                    Autoproj::OSDependencies.operating_system = [['ubuntu'], ['14.04', 'default']]
                    refute Rock.default_loader_is_castxml?(flexmock)
                end
            end
        end

        describe "with C++11 enabled" do
            before do
                @os_package_resolver = flexmock
                @config.should_receive(:get).with('cxx11').and_return(true)
                @config.should_receive(:get).pass_thru
            end

            it "does not override an existing typelib_cxx_loader" do
                @config.set 'typelib_cxx_loader', 'something'
                Rock.setup_cxx11_support(@os_package_resolver, @config)
                assert_equal 'something', @config.get('typelib_cxx_loader')
            end

            it "sets the loader to castxml if it is the default on this OS" do
                Rock.should_receive(:default_loader_is_castxml?).and_return(true)
                Rock.setup_cxx11_support(@os_package_resolver, @config)
                assert_equal 'castxml', @config.get('typelib_cxx_loader')
            end

            it "sets the loader to gccxml if castxml is not the default" do
                Rock.should_receive(:default_loader_is_castxml?).and_return(false)
                Rock.setup_cxx11_support(@os_package_resolver, @config)
                assert_equal 'gccxml', @config.get('typelib_cxx_loader')
            end
        end

        describe "with C++11 disabled" do
            before do
                @os_package_resolver = flexmock
                @config.should_receive(:get).with('cxx11').and_return(false)
                @config.should_receive(:get).pass_thru
            end

            it "does not override an existing typelib_cxx_loader" do
                @config.set 'typelib_cxx_loader', 'something'
                Rock.setup_cxx11_support(@os_package_resolver, @config)
                assert_equal 'something', @config.get('typelib_cxx_loader')
            end

            it "sets the loader to castxml if it is the default on this OS" do
                Rock.should_receive(:default_loader_is_castxml?).and_return(true)
                Rock.setup_cxx11_support(@os_package_resolver, @config)
                assert_equal 'castxml', @config.get('typelib_cxx_loader')
            end

            it "sets the loader to gccxml if castxml is not the default on this OS" do
                Rock.should_receive(:default_loader_is_castxml?).and_return(false)
                Rock.setup_cxx11_support(@os_package_resolver, @config)
                assert_equal 'gccxml', @config.get('typelib_cxx_loader')
            end
        end
    end
end

