
require_relative "./lib/colcon_package.rb"
require_relative "./lib/colcon_import_package.rb"
require_relative "./lib/rosdep_import.rb"

# Declare optione to ask for the desired ros version
# options must have an implementation in the import function of ./lib/rosdep_import.rb
# set default based on OS
os_names, os_versions = Autoproj.workspace.operating_system
if os_names.include?('ubuntu')
    if os_versions.include?('22.04')
        Autoproj.config.set("ROS_VERSION", "humble")
    elsif os_versions.include?('24.04')
        Autoproj.config.set("ROS_VERSION", "jazzy")
    end
end
Autoproj.config.declare "ROS_VERSION",
    "string",
    doc: ["Which ros version should be used to import package depenencies [humble, jazzy, rolling] ?", "you can test other versions, but you need to provide a valid date tag"]


# set an initial value for IMPORTED_ROS_OSDEPS if non-existent (prevents from "undeclared" error)
if (!Autoproj.config.has_value_for?("IMPORTED_ROS_OSDEPS")) then
    Autoproj.config.set("IMPORTED_ROS_OSDEPS", "")
end
if (!Autoproj.config.has_value_for?("IMPORTED_ROS_TAGDATE")) then
    Autoproj.config.set("IMPORTED_ROS_TAGDATE", "")
end

# get the selected ros version
ros_version = Autoproj.config.get("ROS_VERSION")
# get the currently imported version (to detect a version switch by autoproj reconfigure)
imported_ros_osdeps = Autoproj.config.get("IMPORTED_ROS_OSDEPS")
imported_ros_tagdate = Autoproj.config.get("IMPORTED_ROS_TAGDATE")

# set a new default date if main changed
if ros_version != imported_ros_osdeps then
    # set default
    case ros_version
        when "humble"
            Autoproj.config.set("ROS_TAG_DATE", "2024-09-19")
        when "jazzy"
            Autoproj.config.set("ROS_TAG_DATE", "2024-10-18")
        when "rolling"
            Autoproj.config.set("ROS_TAG_DATE", "2024-09-26")
        else
            Autoproj.config.set("ROS_TAG_DATE", "")
    end
end

# default is set if supported version, but still ask
Autoproj.config.declare "ROS_TAG_DATE",
    "string",
    doc: ["Which tag date should be used (use default until issues occur) ?",
        "If you need to change, look up a valid tag date in https://github.com/ros/rosdistro",
        "also please notify maintainers of https://github.com/dfki-ric/ros2-package_set"]


# get the package_set (this) folder to save files (nor where aup is called)
prefix = Autoproj.manifest.package_set("ros2").local_dir
ubuntu_osdeps = prefix+"/ubuntu.osdeps"
ros_osdeps = prefix+"/ros.osdeps"

ros_tag_date = Autoproj.config.get("ROS_TAG_DATE")

# do import if selected version is not already imported, but if config is changed
if !File.exist?(ubuntu_osdeps) || !File.exist?(ros_osdeps) || ros_version != imported_ros_osdeps || ros_tag_date !=  imported_ros_tagdate then
    Autoproj.message "Importing rosdep to #{ubuntu_osdeps} and #{ros_osdeps}" 
    Autoproj.message "Using tag: #{ros_tag_date} of https://github.com/ros/rosdistro to generate osdeps" 
    importer = Ros2::RosdepImporter.new(ubuntu_osdeps, ros_osdeps)
    importer.import(ros_version, ros_tag_date)
    Autoproj.config.set("IMPORTED_ROS_OSDEPS", ros_version)
    Autoproj.config.set("IMPORTED_ROS_TAGDATE", ros_tag_date)
end


# ros_setup_bash = File.join(Autoproj.root_dir, '../install/setup.bash')
# if File.file?(ros_setup_bash)
#     Autoproj.env_source_file ros_setup_bash
# end

