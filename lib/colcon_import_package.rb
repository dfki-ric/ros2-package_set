
require 'json'
require 'fileutils'



# hackily reopen and extend the ImporterPackage class to store cmake args fo a colcon.pkg file
module Autobuild
    class ImporterPackage
        attr_accessor :optional_deps

        #re-implement the original initialize of ImporterPackage + init @colcon_pkg
        def initialize(*args)
            @exclude = []
            @colcon_pkg = Hash.new
            @optional_deps = Array.new
            super
        end

        # function to add a cmake arg
        def add_cmake_arg(value)
            if !@colcon_pkg.has_key?("cmake-args") then
                @colcon_pkg["cmake-args"] = Array.new
            end
            # add it to the stored list
            @colcon_pkg["cmake-args"].push(value)
        end

        # function to add optional dependencies form the mainifest.xml to the package.xml
        def use_optional_dependency(value)
            @optional_deps.push(value)
        end

        # parse/append/write colcon.pkg file if cmake-args were eadded via add_cmake_arg()
        def write_colcon_pkg_file()
            # the cmake-args key is only present if add_cmake_arg was called
            if @colcon_pkg.has_key?("cmake-args") then
                output = Hash.new
                if File.exist?(srcdir + "/colcon.pkg") then
                    File.open(srcdir + "/colcon.pkg") do |file|
                        #load output with existing file to keep all values
                        output = JSON.load(file)
                    end
                end
                # merge new cmake-args to output
                # if !output.has_key?("cmake-args") then
                #     # add key
                #     output["cmake-args"] = Array.new
                # end
                # output["cmake-args"] |= @colcon_pkg["cmake-args"] 

                # overwrite cmake-args, as those which were added by call to pkg.add_cmake_arg() have to be removed from the file
                # (re-loaded) by parsing the file
                output["_comment"] = "cmake-args are autogenerated, they will be overwritten on next autoproj update, change them in your overrides.rb"
                output["cmake-args"] = @colcon_pkg["cmake-args"]
                File.write(srcdir + "/colcon.pkg", JSON.pretty_generate(output))
            end
        end
    end
end

require_relative "package_xml_generation.rb"
@ros2_package_xml_generator = Ros2::PackageXmlGeneration.new

def colcon_import_package(name, type = :import_package, libname: name, workspace: Autoproj.workspace)
    ros_packagename = libname.gsub("/","-")

    send(type, name) do |pkg|
        pkg.post_import do
            #if no package.xml exist, generate one including the dependencies
            @ros2_package_xml_generator.generate(pkg, ros_packagename)
            pkg.write_colcon_pkg_file()

            # for colcon to find chains of pkg-config dependencies without re-sourcing the install/setup.bash,
            # according to https://colcon.readthedocs.io/en/released/developer/environment.html there needs to be an
            # /lib/pkgconfig/*.pc file available so the colcon_pkgconfig adds the package it to the PKG_CONFIG_PATH
            unless File.exist?(pkg.srcdir + "/lib/pkgconfig/init_pkg_config_path.pc") then
                FileUtils.mkdir_p(pkg.srcdir + "/lib/pkgconfig")
                File.write(pkg.srcdir + "/lib/pkgconfig/init_pkg_config_path.pc", "# This files was generated to make colcon to extend the PKG_CONFIG_PATH")
            end
        end

        pkg.post_install do |pkg|
            colcon_dir =  File.expand_path(workspace.root_dir + "/../")
            pkg.progress_start "building %s with colcon in #{colcon_dir}" do
                Autobuild::Subprocess.run(pkg, 'build', 'colcon', 'build','--event-handlers', 'console_direct+', '--packages-select', pkg.name, :working_directory => colcon_dir)
            end
        end

        yield(pkg) if block_given?
    end

    # add a metapackage to have both package definitions in autoproj:
    # with '/' and '-' (colcon cannot have / in package names), so aup
    # needs know the definition with '-' when calls from a plain ros2 package
    # with a manually written package.xml (use - version there to enable colcon to evaluate the dependency)
    metapackage ros_packagename, name
end

def colcon_import_collection_package(checkoutDir, pkgName,type = :colcon_import_package)
    send(type,checkoutDir + "/" + pkgName) do |pkg|
        pkg.importdir = checkoutDir
        yield pkg if block_given?
    end
end

