require 'yaml'
require 'fileutils'
require 'open-uri'

# Importer for rosdep definition files
# use the import() function to save osdeps for a specific ros version, e.g. import("humble")

module Ros2
    class RosdepImporter

        def initialize(osdepfile, rosfile)
            @osdep_file = File.open(osdepfile, 'w')
            @osdep_file.puts "#\n# This file is generated, do not edit!"
            @rosfile = File.open(rosfile, 'w')
            @rosfile.puts "#\n# This file is generated, do not edit!"
        end

        def close()
            @osdep_file.close()
            @rosfile.close()
        end

        def check_pip_gem(osentry)
            # puts osentry
            if (osentry.include?("pip")) then
                if osentry["pip"].is_a?(Hash) then
                    @osdep_file.puts "    pip: #{osentry["pip"]["packages"]}"
                else
                    @osdep_file.puts "    pip: #{osentry["pip"]}"
                end
                return true
            end
            if (osentry.include?("gem")) then
                if osentry["gem"].is_a?(Hash) then
                    @osdep_file.puts "    gem: #{osentry["gem"]["packages"]}"
                else
                    @osdep_file.puts "    gem: #{osentry["gem"]}"
                end
                return true
            end
            return false
        end

        def import_rosdep_osdeps(url)
            URI.open(url) do |f|
                yaml = YAML.load(f);    
                yaml.each do |depname, osdep|
                    if osdep["ubuntu"].is_a?(Array) then
                        @osdep_file.puts  depname + ":\n    ubuntu: #{osdep["ubuntu"]}\n\n"
                    elsif osdep["ubuntu"].is_a?(Hash) then
                        @osdep_file.puts  depname + ":"
                        if (!check_pip_gem(osdep["ubuntu"])) then
                            entry = "    ubuntu:\n"
                            is_pip = false
                            osdep["ubuntu"].each do |os, deps|
                                if os == "*" then
                                    os = "default"
                                end
                                if (deps == nil) then
                                    entry += "        " + os + ": nonexistent\n"
                                else
                                    if (!check_pip_gem(deps)) then
                                        entry +=  "        " + os + ": #{deps}\n"
                                    else
                                        is_pip = true
                                    end
                                end
                            end
                            if (!is_pip) then
                                @osdep_file.puts entry
                            end
                        end
                        @osdep_file.puts
                    end
                end
            end
        end

        def import_ros_packages(rosversion)
            url = "https://raw.githubusercontent.com/ros/rosdistro/refs/heads/master/"+rosversion+"/distribution.yaml"
            URI.open(url) do |f|
                yaml = YAML.load(f);    
                yaml["repositories"].each do |depname, content|
                    if content.has_key?("release") && content["release"].has_key?("packages") then
                        content["release"]["packages"].each do |package|
                            @rosfile.puts  package + ":"
                            @rosfile.puts "    ubuntu: ros-"+rosversion+"-"+package.gsub(/_/, '-')
                        end
                    else
                        @rosfile.puts  depname + ":"
                        @rosfile.puts "    ubuntu: ros-"+rosversion+"-"+depname.gsub(/_/, '-')
                    end
                end
            end
        end

        def import(rosversion, date)
            rostag=rosversion+"/"+date
            @osdep_file.puts "# based on https://github.com/ros/rosdistro tag #{rostag}\n#"
            @rosfile.puts "# based on https://raw.githubusercontent.com/ros/rosdistro/refs/heads/master/"+rosversion+"/distribution.yaml\n#"
            import_rosdep_osdeps("https://raw.githubusercontent.com/ros/rosdistro/refs/tags/#{rostag}/rosdep/base.yaml")
            import_rosdep_osdeps("https://raw.githubusercontent.com/ros/rosdistro/refs/tags/#{rostag}/rosdep/python.yaml")
            import_rosdep_osdeps("https://raw.githubusercontent.com/ros/rosdistro/refs/tags/#{rostag}/rosdep/ruby.yaml")
            import_ros_packages(rosversion)
        end
    end
end
