# vg
Vagrant based deployment of Gluster and Glusto, via Ansible

**What is it**

Simplify the deployment of Gluster + Glusto, its testing suite and framework, to enable easier testing of Gluster in an isolated (VM) environment.
The deployment uses Gluster-Ansible to deploy Gluster in a standard manner.

**Requirements**

- Linux OS (developed and tested on Fedora 29/30)
- Git to clone the repo
- Vagrant, libvirt (+KVM), libvirt-provider for vagrant, Ansible.

**Basic usage**

1. Clone the repo to your computer.
2. Assuming you have the basic requirements on the host (Ansible, libvirt, Vagrant, libvirt-provider for vagrant) then ```vagrant up``` should bring the environment up in ~4-5m (might take longer in the initial run, as it downloads the CentOS box).
3. To run tests, SSH to node-0 via ```vgrant ssh node-0``` , then switch to root ```su -``` (password is 'foobar').
You can now ```cd /root/glusto-tests``` and run the tests, as you would normally with Glusto.
For example:
```glusto -c /root/gluster_tests_config.yml --pytest='-v -x tests/functional/bvt/test_cvt.py  --junitxml=/tmp/cvt-junit.xml'```
