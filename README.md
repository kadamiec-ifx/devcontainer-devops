# DevContainer set-up for WSL/remote-shell development
Read more about VSCode Dev Containers: https://code.visualstudio.com/docs/devcontainers/containers

Content of this repository must be placed in the `.devcontainer` subdirectory of project/workspace folder, so VSCode can auto-detect the container configuration. See instructions below
DevContainers can be used in any system with Docker => WSL, EC2, VM, LXC Container etc

# Highlights
* Preinstalled with AWS CLI tools including Elastic Beanstalk and SSM
* Terraform support via `tfenv` (terraform version manager)
* Support for running Docker-Outside-Of-Docker (mounts host's `/var/run/docker.sock`)
* `.devcontainer/.mount` folder gets mounted into `~/.mount` for persistence of dotfiles/bash_history/credentials 
* stow mounts `~/.mount/dotfiles` and `~/.mount/dotfiles_priv`
* ssh keys will be passed by vscode via SSH Agent
* git username/email will be passed from the host that will run the devcontainer
* Prebuild/central image from ECR is also supported (see `devcontainer.json` help)
* ⚠️ may expose SSH server for additional capabilities - can be disabled

# Installation / Initial Set-up
1. Open WSL and run this snippet - it will add your WSL user ID and DOCKER group id to environment variables for VSCode to use later
```bash
cat << EOF >> ~/.profile
export UID
export USERNAME=\$USER
export DOCKER_GID=\$(getent group "docker" | awk -F: '{print \$3}')
EOF
```
1. Clone repo (sample project or .devcontainer only) into WSL e.g. `/workWSL` (don't use shared volume between Windows and WSL due to performance issues).
Create files you want to persist across DevContainer rebuilds
Then run the `code .` to open WSL local directory in VSCode
```bash
git clone --recurse-submodules git@github.com:kadamiec-ifx/vscode-devcontainer.git /workWSL/devops
cd /workWSL/devops

# Dotfiles are managed as part of the solution with stow, but they can be also managed with VSCode settings
# done in devcontainer.json also
cd .devcontainer
DOTFILESDIR="./.mount/dotfiles_priv"
mkdir -p $DOTFILESDIR/.aws
mkdir -p $DOTFILESDIR/.kube
mkdir -p $DOTFILESDIR/gopass_store
touch $DOTFILESDIR/.bash_history
touch $DOTFILESDIR/.zsh_history
cd ..

# Open
code devops-test.code-workspace
```
1. Open the folder or workspace. Press F1/CTRL+SHIFT+P and select `Dev: Reopen in Container`. Wait for build to finish and enjoy the containerized development environment.

## Additional set-up
### SSH keys from Windows host
```
## ⚠️Run as elevated / Admin ⚠️
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'
Remove-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0 # Default one is too old and will cause errors with vscode/devcontainers
# Restart computer
winget install Microsoft.OpenSSH.Preview --override ADDLOCAL=Client
Start-Service ssh-agent
Set-Service ssh-agent -StartupType Automatic
Get-Service ssh-agent
```

### GPG pin entry on windows host
```
#vi .gnupg/gpg-agent.conf
pinentry-program /mnt/c/Users/<!!!USER!!!>/AppData/Local/Programs/Git/usr/bin/pinentry.exe
```


## Git Config
```bash
git config --global push.autoSetupRemote true
git config --global push.default current
git config --global init.defaultBranch develop
```
## AWS sso how-to
```bash
aws configure sso
# Start URL: https://<ORG_NAME>.awsapps.com/start#/
# Set parameters and at the end set the Profile Name something like: `<ORG_NAME>-<ACCOUNT_NAME>

# next time log with one of the profile to gain access to all profiles
aws-sso-login <profile_name> # alias for: `aws sso login --profile <profile_name>`

# set current profile
aws-sso-set-profile=<profile_name>
aws-sso-whoami # aliast for: `aws sts get-caller-identity`

# use explicit key/secret/session (⚠️ priority over evyrthing else, unset once done⚠️)
export AWS_ACCESS_KEY_ID=<access_key>
export AWS_SECRET_ACCESS_KEY=<secret_key>
export AWS_SESSION_TOKEN=<session_token>
export AWS_DEFAULT_REGION=<region>

aws-sso-whoami

aws-sso-reset-profile # or unset AWS_DEFAULT_PROFILE
```

# Standalone devcontainers build/run (to use outside of VSCode)
```bash
cd .devcontainer
# build and run ubuntu
make ubuntu build run
# build only
make build-ubuntu
# run
make ubuntu run
```

## EKS
```
aws eks update-kubeconfig --region $AWS_REGION --name <cluster-name>
kubectl config get-contexts
```

