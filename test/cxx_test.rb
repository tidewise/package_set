require 'test_helpers'
require 'rock/cxx'

module Rock
    describe "setup_cxx_support" do
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
    end
end

