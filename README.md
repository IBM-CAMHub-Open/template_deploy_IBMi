### License and Maintainer

Copyright IBM Corp. 2019

Template Version - 1.0.0

Here terraform samples are to perform IBM i related operations.

Prerequisites

    You have an instance of PowerVC 1.3.3 (or newer) running
    You have a IBM i (or newer) image loaded within PowerVC; you could modify the cloud-init script to also work with your operating system of choice
    If you're using this for anything beyond a proof-of-concept, within main.tf, please also take the added step of setting insecure=false and set the cacert option to the contents of the PowerVC certificate (/etc/pki/tls/certs/powervc.crt)

Templates details
1. template_deploy_IBMi
    Perform IBM i simple deployment

2. template_install_PTF_from_media
    The template is to install PTF group, CUM packages from media files. 
    
3. template_install_PTF_from_savf
    The template is to install individual PTFs from SAVF files.

4. template_ansible_server
    The template is to install an ansible server on a linux system.