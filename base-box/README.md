# Base Vagrant box setup

This directory contains all resources required to create a local Vagrant box that will be reused by the demo Virtual
Machines.

## Implementation details

This added complexity is do make sure the box that will be used will have the latest updates of Rocky Linux packages.
Unfortunately, Vagrant boxes are not kept updated as much as we would like to.

This also includes kernel upgrades, so the Virtualbox Guest Additions kernel module needs to be recompiled in order to
have this setup.

The problem is, the vast majority of Linux distribution boxes doesn't come with kernel headers and C related packages
installed in order to reduce the size of those boxes, but those are required to recompile the Virtualbox Guest Additions
kernel module to match the current kernel in execution.

The Vagrant vbguest plugin partially takes care of solving that, but it also comes with the "chicken and egg" problem,
because it requires the kernel related packages that matches the current kernel running.

So, in order to have things working automatically is necessary:

1. Upgrade all packages installed, which will include a newer kernel package installed as well.
1. Reboot the VM, so the newer kernel will be used in the system bootstrap.
1. Install the kernel development packages, that needs to match the kernel version. This is done automatically.
1. Reboot the VM again, this time to make sure vbguest will do it's job and create a new kernel module.

The `Makefile` will make those steps in this exact order. Also, to make sure we don't repeat steps unnecessarily, a
hack is used inside the `Vagrantfile` to enable/disable vbguest dynamically by using environment variables.

The `Makefile` has three targets:

1. `box`: used to create a VM instance, update it and package the result as a box file
1. `add-box`: adds the box to Vagrant local cache. After that, the box can be used
1. `remove-box`: removes the box from the Vagrant local cache.

## Usage

You shouldn't be creating several times this base box: unless there are newer package updates to apply, doing it once
should be enough.

If you need to make changes to the Choria Demo environment, this is not the place to make it unless that means doing
modifications that should be replicated to all VM's, but even so, the recommendation is to do it in the other
`Vagrantfile` to keep things simple. The base box was created to include updated packages and nothing else.

Another valid reason to run this automation again is if you changed the Virtualbox version and the Guest Additions is
not working properly, thus needs to be replaced. See the vbguest in order to enable it to access the Guest Additions
CDROM with the required source code.

If you need, for any reason, to change the box name, refer to the file `automation_config.json` (one level up this
README) to change it. This file exists to make things DRY.

## Running on Microsoft Windows

The Powershell script `manage-box.ps1` has the same functionality of the `Makefile`.
