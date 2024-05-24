# Autoproj package set for managing ROS2 workspaces

Contents of this repository was initiated and is currently developed at the
[Robotics Innovation Center](http://robotik.dfki-bremen.de/en/startpage.html) of the
[German Research Center for Artificial Intelligence (DFKI)](http://www.dfki.de) in Bremen.

## License

[BSD Clause 3](https://opensource.org/licenses/BSD-3-Clause)<br> - Copyright DFKI GmbH

## Autoproj

Autoproj is a workspace management tool that provides the functionality of WStool/VCSTool and rosdep combined.

Autoproj seperates package and workspace definitions.

Package definitions are stored in a "package set", workspaces in a "buildconf" that is checked out into your workspace in a folder called "autoproj".

### A package_set (this repository) allows to define available packages for the workspace, it has three main configuration files 

* source.yml - Defines the location and type of the source to download (e.g. git, archive, ...) and can add automatically add patches after doenload
* *.autobuild file(s) - Define which packages are available and how autoproj should handle the code (autoproj may generate additional files, like a colcon.pkg file with cmake args). Autoproj can also build workspaces, in the ROS2 case you should still use colcon.
* *.osdeps file(s) - A list of OS dependencies, in this package set, the ros 2 wstool definitions is already imported.

Additional files are for advanced usage (see the autoproj documantation).

### A buildconf ("autoproj" folder in the Worksapce) 

A buildconf defines which packages from the package_set are actually installed into the workspace.

It is part of the workspace and thus can easily be shared among a team of developers (e.g. as a git repo).

Is also may contain "overrides" to adapt your checkouts/builds from the defaults in the package_set, this includes switching branches or setting specific cmake args for single libraries and adding patches.

* In the init.rb you define server configurations for source names used in the package set (e.g. "github")
* The overrides.d folder may contain .xml files with changes of location or branches (e.g. when you workspace is using a fork) or add patches to be auto-applied on checkout/update
* The overrides.rb file can change build definitions (e.g. build a scecific file in debug mode)


# Installing

This decribes installing for the first time, some parts can be omitted for future checkouts

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
* `source /opt/ros/humble/setup.bash`
* `colcon build`

**Sometimes depending packages are not found through pkg-config on first try, in this case: call `source install/setup.bash` and try `colcon build` again**


# Updating
You can update autoproj-defined packages in a single command. To do this source the src/env.sh script and call `autoproj update` when you append a package name or forlder, onthe that package AND its dependencies are updated.


# Tips

* colcon_import_packages are often using pkg-config to find dependencies. When you get the error message "A required package was not found" when building, run colcon build with `--event-handlers console_direct+` in order to see which package is not found

* colcon_import_packages are beneric cmake packages using some automation to be able to be compiled with colcon, as generating package.xml and colcon.pkg files, and generating a .ps file to make pkg-config work, but in some cases, you might need to `source install/setup.bash` again so colcon can find everything.