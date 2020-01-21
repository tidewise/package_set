require 'test_helpers'
require 'rock/python'
require 'autoproj/test'

module Rock
    describe "activate_python" do
        before do
            @pkg = Autobuild::Package.new
            @ws = ws_create
            flexmock(@pkg)
            @pkg.prefix = "/tmp/install/foo/"

            @test_python = File.join(Dir.tmpdir(), "test-python")
            if !File.exist?(@test_python)
                File.symlink("/usr/bin/python",
                             @test_python)
            end
        end
        after do
            if !File.exist?(@test_python)
                File.rm(@test_python)
            end
        end

        it "does get the python version" do
            assert_raises { Rock.get_python_version("no-existing-file") }
            assert_raises { Rock.get_python_version(__FILE__) }

            assert(Rock.get_python_version("/usr/bin/python") != "")
        end

        it "does validate the python version" do
            version, valid = Rock.validate_python_version("/usr/bin/python",nil)
            assert(version =~ /[0-9]+\.[0-9]+/)
            assert(valid)

            version_a, valid = Rock.validate_python_version("/usr/bin/python", ">2.0")
            assert(version_a == version)
            assert(valid)

            version_a, valid = Rock.validate_python_version("/usr/bin/python", "<100.0")
            assert(version_a == version)
            assert(valid)

            version_a, valid = Rock.validate_python_version("/usr/bin/python", ">100.0")
            assert(version_a == version)
            assert(!valid)
        end

        it "does find python" do
            assert_raises { Rock.find_python(ws: @ws, version: ">100.0" ) }
            python_bin, version = Rock.find_python(ws: @ws, version: "<100.0" )
            assert(File.exist?(python_bin))
            assert(version =~ /[0-9]+\.[0-9]+/)
        end

        it "custom resolve python" do
            python_bin_resolved, version_resolved = Rock.custom_resolve_python(ws: @ws,
                                                                              bin: @test_python)
            assert(python_bin_resolved)
            assert_raises { Rock.custom_resolve_python(ws: @ws,
                                                       bin: @test_python,
                                                       version: ">100.0") }

            assert_raises { Rock.custom_resolve_python(ws: @ws,
                                                      bin: "no-existing-python") }


            python_bin, version = Rock.find_python(ws: @ws)
            @ws.config.set("python_executable", @test_python)
            @ws.config.set("python_version", version)

            python_bin_resolved, version_resolved = Rock.resolve_python(ws: @ws)
            assert(python_bin_resolved == @test_python)
            assert(version_resolved == version)

            assert_raises { Rock.resolve_python(ws: @ws, version: ">100.0") }

            @ws.config.set("python_executable", nil)
            @ws.config.set("python_version", nil)
        end

        it "does update the python path" do
            python_bin = `which python`
            assert($? == 0, "This test requires python to be available on your"\
                   " system, so please install before running this test")

            Rock.activate_python_path(@pkg, ws: @ws)

            found_path = false
            path_pattern = File.join(@pkg.prefix,"lib","python.*","site-packages")
            @ws.env.environment["PYTHONPATH"].each do |p|
                if p =~ /#{path_pattern}/
                    found_path = true
                end
            end
            assert(found_path)
            assert(!@ws.config.has_value_for?('python_executable'))
            assert(!@ws.config.has_value_for?('python_version'))

            assert_raises { Rock.activate_python_path(@pkg, ws: @ws, version: ">100.0") }

            Autobuild.programs["python"] = "no-existing-executable"
            assert_raises { Rock.activate_python_path(@pkg, ws: @ws, version: ">100.0") }
            Autobuild.programs["python"] = nil
        end

        it "does activate_python" do
            Rock.activate_python(ws: @ws)
            assert(@ws.config.has_value_for?('python_executable'))
            assert(@ws.config.has_value_for?('python_version'))
        end
    end
end
