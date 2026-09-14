
require 'fileutils'

require_relative "colcon_common.rb"
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

        colcon_build_hook(pkg, workspace)

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

