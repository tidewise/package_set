require 'test_helpers'
require 'rock/cxx11'

module Rock
    describe "setup_cxx11_support" do
        before do
            @config = Autoproj::Configuration.new
        end

        describe "with C++11 enabled" do
            before do
                @os_package_resolver = flexmock
                flexmock(Rock).should_receive(:has_cxx11_support?).and_return(true)
                flexmock(@config).should_receive(:get).with('cxx11').and_return(true)
                flexmock(@config).should_receive(:get).pass_thru
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
                flexmock(Rock).should_receive(:has_cxx11_support?).and_return(true)
                flexmock(@config).should_receive(:get).with('cxx11').and_return(false)
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

