# Autoproj package set for managing ROS2 workspaces

Contents of this repository was initiated and is currently developed at the
[Robotics Innovation Center](http://robotik.dfki-bremen.de/en/startpage.html) of the
[German Research Center for Artificial Intelligence (DFKI)](http://www.dfki.de) in Bremen.

## License

[BSD Clause 3](https://opensource.org/licenses/BSD-3-Clause)<br> - Copyright DFKI GmbH

## Autoproj

Autoproj is a workspace management tool that provides the functionality of WStool/VCSTool and rosdep combined.

Autoproj separates package and workspace definitions.

Package definitions are stored in a "package set", workspaces in a "buildconf" that is checked out into your workspace in a folder called "autoproj".

### A package_set (this repository) allows to define available packages for the workspace, it has three main configuration files 

* source.yml - Defines the location and type of the source to download (e.g. git, archive, ...) and can automatically add patches after download
* *.autobuild file(s) - Define which packages are available and how autoproj should handle the code (autoproj may generate colcon configuration, like cmake args and package metadata). For colcon packages, `autoproj build` (`amake`) calls `colcon build --packages-select <package>` in the folder above the autoproj workspace, for the package and (unless run with `-n`) all its dependencies, checking out missing ones first.
* *.osdeps file(s) - A list of OS dependencies, in this package set, the ROS 2 dependencies are generated from rosdep for the configured ROS_DISTRO (ubuntu.osdeps-<distro>, ros.osdeps-<distro>).

Additional files are for advanced usage (see the autoproj documentation).

### A buildconf ("autoproj" folder in the workspace)

A buildconf defines which packages from the package_set are actually installed into the workspace.

It is part of the workspace and thus can easily be shared among a team of developers (e.g. as a git repo).

It also may contain "overrides" to adapt your checkouts/builds from the defaults in the package_set, this includes switching branches or setting specific cmake args for single libraries and adding patches.

* In the init.rb you define server configurations for source names used in the package set (e.g. "github")
* The overrides.d folder may contain .yml files with changes of location or branches (e.g. when your workspace is using a fork) or add patches to be auto-applied on checkout/update
* The overrides.rb file can change build definitions (e.g. build a specific package in debug mode)


# Installing

This describes installing for the first time, some parts can be omitted for future checkouts

* `sudo apt install ruby ruby-dev`
* `mkdir src`
* `cd src`
* `wget http://rock-robotics.org/autoproj_bootstrap`
* `ruby autoproj_bootstrap git https://github.com/dfki-ric/ros2-buildconf`
  * answer the questions, when in doubt hit enter to use the default
* `git config --global credential.helper cache`

* edit the src/autoproj/manifest file to only include the packages you want in your workspace (remove the ros-2 entry)
* `. env.sh`
* `autoproj update [PACKAGE_TO_INSTALL]`
  * answer the questions, when in doubt hit enter to use the default

* `cd ..`
* `sudo apt install python3-colcon-common-extensions` if not already installed
* `source /opt/ros/$ROS_DISTRO/setup.bash` (e.g. humble or jazzy)
* `colcon build`

**Sometimes depending packages are not found through pkg-config on first try, in this case: call `source install/setup.bash` and try `colcon build` again**


# Updating
You can update autoproj-defined packages in a single command. To do this source the src/env.sh script and call `autoproj update`. When you append a package name or folder, only that package AND its dependencies are updated.


# Defining packages

In addition to the standard autoproj package types, this package set provides these functions for *.autobuild files:

* `colcon_package "name"` - a package that already has a package.xml (e.g. ROS 2 packages)
  * `move_to: "folder"` checks the package out into a subfolder, `importdir: "dir"` uses a different checkout directory than the package name
* `colcon_import_package "path/name"` - a generic cmake package without package.xml (e.g. Rock packages with a manifest.xml)
  * colcon package names cannot contain "/", so the package is also available under the name "path-name"
  * `libname: "name"` sets a different colcon package name (e.g. when another package refers to it by that name)
* `colcon_import_collection_package "dir", "name"` - a colcon_import_package "dir/name" from a repository "dir" containing several packages

Within the definition block (or in the overrides.rb of the buildconf), packages can be adapted further:

```ruby
colcon_import_package "base/types" do |pkg|
    pkg.add_cmake_arg "-DUSE_SISL=ON"
    pkg.use_optional_dependency "gui/vizkit3d"
end
```

* `pkg.add_cmake_arg` passes an argument to cmake when the package is built by colcon
* `pkg.use_optional_dependency` makes colcon build that package first, if it is part of the workspace (for colcon_import_packages)

If a dependency is known to colcon under a different name than its autoproj package name (e.g. "slam/slam3d" vs "slam3d"), add the mapping to dependency_name_overrides.yml.


# Configuration options

These can be changed with `autoproj reconfigure`:

* ROS_DISTRO - the ROS 2 distribution to generate OS dependencies for (defaults to the sourced ROS 2 environment, otherwise to the one matching the Ubuntu version)
* ROS_OSDEP_FORCE_UPDATE - regenerate the OS dependency definitions from rosdep once
* COLCON_USE_SYMLINK_INSTALL - call colcon with `--symlink-install` when building with autoproj


# Tips

* colcon_import_packages are often using pkg-config to find dependencies. When you get the error message "A required package was not found" when building, run colcon build with `--event-handlers console_direct+` in order to see which package is not found

* colcon_import_packages are generic cmake packages; autoproj generates the colcon configuration needed to build them with colcon, but in some cases, you might need to `source install/setup.bash` again so colcon can find everything.
