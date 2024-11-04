
require_relative "./lib/colcon_package.rb"
require_relative "./lib/colcon_import_package.rb"
require_relative "./lib/rosdep_import.rb"


Autoproj.config.declare "ROS_VERSION",
"string",
default: "humble",
doc: ["Which ros version should be used to import paxckage depenencies [humble, jazzy, rolling] ?"],
possible_values: ["humble", "jazzy", "rolling"]

if (!Autoproj.config.has_value_for?("IMPORTED_ROS_OSDEPS")) then
    Autoproj.config.set("IMPORTED_ROS_OSDEPS", "")
end

prefix = Autoproj.manifest.package_set("ros2").local_dir
ubuntu_osdeps = prefix+"/ubuntu.osdeps"
ros_osdeps = prefix+"/ros.osdeps"
ros_version = Autoproj.config.get("ROS_VERSION")
imported_ros_osdeps = Autoproj.config.get("IMPORTED_ROS_OSDEPS")

if !File.exist?(ubuntu_osdeps) || !File.exist?(ros_osdeps) || ros_version != imported_ros_osdeps then
    Autoproj.message "Importing rosdeps to " + prefix
    importer = Ros2::RosdepImporter.new(ubuntu_osdeps, ros_osdeps)
    importer.import(ros_version)
    Autoproj.config.set("IMPORTED_ROS_OSDEPS", ros_version)
end



# os_names, os_versions = Autoproj.workspace.operating_system
# if os_names.include?('ubuntu')
#     if os_versions.include?('focal')
#         Autoproj.message ("Load ros2 osdeps with the suffix 'focal'")
#         Autoproj.workspace.osdep_suffixes << 'focal'
#         Autoproj.message Autoproj.workspace.osdep_suffixes
        
        
#     elsif os_versions.include?('jammy')
#         Autoproj.message ("Load ros2 osdeps with the suffix 'jammy'")
#         Autoproj.workspace.osdep_suffixes << 'jammy'
#     else
#         Autoproj.error("Unsupported ubuntu version #{is_versions}")
#     end
# else
#     Autoproj.error("Unsupported os version: #{os_names}")
# end

# ros_setup_bash = File.join(Autoproj.root_dir, '../install/setup.bash')
# if File.file?(ros_setup_bash)
#     Autoproj.env_source_file ros_setup_bash
# end

