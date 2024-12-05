require 'yaml'
module Ros2
    class PackageXmlGeneration
        def initialize(ws: Autoproj.workspace)
            pkg_set_path = File.dirname(caller_locations.first.path)
            depname_overrides = File.join(pkg_set_path, '../dependency_name_overrides.yml')
            @dependdency_name_overrides = YAML.load_file(depname_overrides, fallback: {})
        end

        def generate(pkg, dependencyname)
            #puts "generate_package_xml" + pkg.srcdir + "/package.xml"
            if !File.exist?(pkg.srcdir + "/package.xml") then
                puts "  package.xml not present, generating for " + pkg.name
                content = \
%{<?xml version="1.0"?>
<package format="2">
    <name>#{dependencyname}</name>
    <version>0.0.0</version>
    <description>auto generated file, see manifest.xml for information</description>
}
                pkg.dependencies.each do |dep|
                    # get a name from override list
                    depname = @dependdency_name_overrides[dep]
                    # if no name is in the list, generate based on the generatot naming scheme
                    if  depname == nil
                        depname = dep.gsub("/","-")    
                    end
                    content = content + "    <depend>#{depname}</depend>\n"
                end

                pkg.optional_deps.each do |dep|
                    content = content + "  <depend>#{dep.gsub("/","-")}</depend>\n"
                end

                content += \
%{   <maintainer email="steffen.planthaber@dfki.de">Steffen Planthaber</maintainer>
    <license>Copyright DFKI</license>
    <export>
        <build_type>cmake</build_type>
    </export>
    </package>
}
                #puts content
                File.open(pkg.srcdir + "/package.xml", 'w') { |file| file.write(content) }
            end
        end
    end
end
