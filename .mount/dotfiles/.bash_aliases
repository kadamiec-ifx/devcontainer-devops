GREEN='\033[0;32m'
RESET='\033[0m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
RED='\033[1;31m'
PURPLE='\033[1;35m'
GRAY='\033[1;30m' # New gray color
RESET='\033[0m'

## Standard/obvious Aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias susu='sudo su -'
alias scrx='screen -x'
alias beep='echo -e "\007"'
alias dl="docker-list"
alias vi="vim"
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias load-aliases="source ~/.bash_aliases"
alias etmux="vim ~/.tmux.conf"
alias edit-aliases="vim ~/.bash_aliases"
alias export-wd="export WD=$PWD"
alias findfile="find . -type f -iname"
alias finddir="find . -type d -iname"
alias path-add-pwd="export PATH=$PATH:$PWD"
alias python-activate-venv="source .venv/bin/activate"

#git
alias ga="git add"
alias gl="git log --oneline --decorate --graph"
alias gs="git status"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias gdiff="git diff --color-words"
alias gc="git commit -m"
alias gcane="git commit --amend --no-edit"

# Terraform
alias tfi="terraform init"
alias tfg="terraform get"
alias tfgu="terraform get -update"
alias tfv="terraform validate"
alias tfp="terraform plan"
alias tfa="terraform apply"
alias tfc="terraform console"
alias tfaa="terraform apply -auto-approve"

# AWS Aliases
alias aws-ec2-list="aws ec2 describe-instances --output=table --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==\`Name\`].Value | [0],State.Name,PublicIpAddress,PrivateIpAddress,LaunchTime]'"
alias aws-cloudfront-list="aws cloudfront list-distributions --output json | jq -r '.DistributionList.Items[] | [.Id, .Comment, .DomainName] | @tsv' | sort -k2"
alias aws-cloudfront-invalidate="aws cloudfront create-invalidation --paths '/*' --distribution-id $1"
alias aws-reset-env="unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN"
alias aws-sso-whoami="aws sts get-caller-identity"
alias aws-sso-list-profiles="aws configure list-profiles"
alias aws-sso-reset-profile="unset AWS_DEFAULT_PROFILE"
alias aws-spot-request-history="aws ec1 describe-spot-instance-requests --query 'SpotInstanceRequests[*].[SpotInstanceRequestId,Tags[?Key==\`Name\`].Value | [0],LaunchSpecification.InstanceType,SpotPrice,State,Status.Code,Status.UpdateTime]'"
alias aws-set-output="aws configure set default.output"


# Docker Aliases
alias dls="docker ps"
alias dlsa="docker ps -a"
alias dc="docker compose"
alias dcl="docker compose logs"
alias dce="docker compose exec"
alias lazydocker="docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.lazydocker:/.config/jesseduffield/lazydocker lazyteam/lazydocker"

# Functions
## Utility use ripgrep/rg when possible
function find-grep() {
  local IN_DIR="."
  local FILEMASK="*"
  if [ -z "$1" ]; then echo "Usage: find-grep <file-pattern> <search-pattern> [directory]"; return 1; fi
  if [ ! -z "$2" ]; then FILEMASK=$3; fi
  if [ ! -z "$3" ]; then IN_DIR=$3; fi
  find "$IN_DIR" -type f -name "$FILEMASK" -exec grep -Hni "$2" {} \;
}
function devcontainer-setup() {
    echo "Dev container setup NOT_IMPLEMENTED"
}

# Import <key>=<value> files to ENV variables
# Lines starting with "#" or space/empty lines are omited
# Arguments $1 - file to import/process
function import-envfile () {
  if [ -z "$1" ]; then ENVFILE=".env"; else ENVFILE="$1"; fi
  echo "Processing $ENVFILE"
  source $ENVFILE
  export $(grep -Ev '^(\s|#)' "$ENVFILE" | envsubst | xargs)
  # export $(grep -v '^#' .env | xargs -d '\n')
}

# Usage: echo -E "what3ver" | regex '[0-9]' 
# This is ERE/POSIX so [[:digit:]] not \d
function regex { 
	awk 'match($0,/'$1'/, ary) {print ary['${2:-'0'}']}';
}

function aws_helper_get_instance_id() {
  INSTANCE_NAME=$1
  if [[ $INSTANCE_NAME == i-* ]]; then
      INSTANCE_ID=$INSTANCE_NAME
  else
      INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$INSTANCE_NAME" --query "Reservations[].Instances[].InstanceId" --output text)
  fi
  echo $INSTANCE_ID
}

## AWS
function aws-ssm-session() {
    INSTANCE_NAME=$1
    if [[ $INSTANCE_NAME == i-* ]]; then
        INSTANCE_ID=$INSTANCE_NAME
    else
        INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$INSTANCE_NAME" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId" --output text)
        
    fi
    echo -e "${GREEN}Starting SSM session for instance $INSTANCE_ID${RESET}"
    aws ssm start-session --target "$INSTANCE_ID"
}
function aws-sso-set-profile() { export AWS_DEFAULT_PROFILE=$1; }
function aws-set-output() {
    aws configure set default.output $1
    export AWS_DEFAULT_OUTPUT=$1
}
function aws-sso-login() {
    if [ -z "$1" ]; then echo "Usage: aws-sso-login <profile-name>"; return 1; fi
    aws sso login --profile $1
    if [ $? -eq 0 ]; then
      echo "Exit code is 0"
      AWS_DEFAULT_PROFILE=$1
      export AWS_DEFAULT_PROFILE
      echo -e "${GREEN}AWS_DEFAULT_PROFILE = $AWS_DEFAULT_PROFILE ${RESET}"
    fi
}
function aws-input-credentials() {
  echo -n "Enter AWS Access Key ID: "
  read aws_access_key_id
  echo -n "Enter AWS Secret Access Key: "
  read -s aws_secret_access_key

  aws-reset-env
  aws-sso-reset-profile

  export AWS_ACCESS_KEY_ID="$aws_access_key_id"
  export AWS_SECRET_ACCESS_KEY="$aws_secret_access_key"

  echo "AWS credentials captured and exported to environment variablesa. You are logged in as:"
  aws-sso-whoami
}

function aws-assume-role() {
  ROLE_NAME=$1
  ACCOUNT_ID=$2
  EXTERNAL_ID=$3

  if [ -z "$ROLE_NAME" ]; then echo "Usage: aws-assume-role <role-name> [account-id] [external-id]"; return 1; fi
  
  if [ -z "$ACCOUNT_ID" ]; then ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text); fi
  if [ -z "$EXTERNAL_ID" ]; then EXTERNAL_ID="NONE"; fi

  assumed_role=$(aws sts assume-role --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}" --role-session-name AWSCLI-Session --external-id ${EXTERNAL_ID} --output json)
  export AWS_ACCESS_KEY_ID=$(echo $assumed_role | jq -r '.Credentials.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo $assumed_role | jq -r '.Credentials.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo $assumed_role | jq -r '.Credentials.SessionToken')
  aws-sso-whoami
}

function aws-ssm-exec() {
  instance_id=$(aws_helper_get_instance_id $1)
  document_name="AWS-RunShellScript"
  shift
  command="$@"

  echo "Executing on $instance_id the command[$#]: $command"

  # Execute the command using AWS CLI
  command_id=$(aws ssm send-command \
    --instance-ids $instance_id \
    --document-name $document_name \
    --parameters commands="$command" \
    --query "Command.CommandId" \
    --output text)

  if [ -z "$command_id" ]; then
    echo "ERROR: Failed to execute the command"
    return 1
  fi

  # Wait for the command to complete
  aws ssm wait command-executed \
    --instance-id $instance_id \
    --command-id $command_id

  # Retrieve the command output
  output=$(aws ssm get-command-invocation \
    --instance-id $instance_id \
    --command-id $command_id \
    --query "StandardOutputContent" \
    --output text)

  echo "Command output:"
  echo "$output"
}

function aws-ecs-shell() {
  aws ecs execute-command \
  --region $AWS_REGION \
  --cluster $1 \
  --task ECS_TASK_ID \
  --container CONTAINER_NAME \
  --command "/bin/bash" \
  --interactive
}

function aws-ecs-list-containers() {
  aws ecs list-containers \
  --cluster $1 \
  --region $AWS_REGION
}

function aws-paramstore-list-secrets() {
  PARAMETERS=$(aws ssm describe-parameters --query "Parameters[?Type=='SecureString']" --output json)
  PARAMETER_NAMES=$(echo $PARAMETERS | jq -r '.[].Name' | sort)
  echo "$PARAMETER_NAMES"
}

function aws-paramstore-get-secret() {
  if [ -z "$1" ]; then echo "Usage: aws-paramstore-get-secret <secret>"; fi
  aws ssm get-parameter --name "$1" --query "Parameter.Value" --with-decrypt --output text
}

function aws-set-credentials-from-gitlab() {
  local SCOPE="" 
  if [ ! -z "$1" ]; then local SCOPE="$1"; fi

  echo "Getting variable for scope: $SCOPE";  

  aws-reset-env
  export AWS_ACCESS_KEY_ID=$(glab variable get -s $SCOPE AWS_ACCESS_KEY_ID)
  if [ -z AWS_ACCESS_KEY_ID ]; then
    echo "ERROR: AWS_ACCESS_KEY_ID not found in GitLab variables for scope: $SCOPE. Maybe you are missing the scope?"
    return;
  fi
  export AWS_SECRET_ACCESS_KEY=$(glab variable get -s $SCOPE AWS_SECRET_ACCESS_KEY)

}

function docker-shell() {
        #shell="bash";
        # if [ -z ${var+x} ]; then echo "var is unset"; else echo "var is set to '$var'"; fi
        if [ -z "$1" ]; then echo "Usage: docker-shell ContainerName [shell(bash)]"; return 1; fi
        if [ -z "$2" ]; then shell="bash"; else shell=$2; fi
        docker exec -it $1 "$shell"
}

# Sorted and colored list of docker containers
function docker-list() {
	# docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" | (read -r; printf "%s\n" "$REPLY"; sort -k2,2 -f )
  docker ps --all --format "{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}" \
      | (echo -e "CONTAINER_ID\tNAMES\tIMAGE\tPORTS\tSTATUS" && cat) \
      | awk -v green="$GREEN" -v blue="$BLUE" -v gray="$GRAY" -v reset="$RESET" '{printf gray"%s\t"green"%s\t"blue"%s\t"reset"%s %s %s %s %s %s %s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10;}' \
      | column -s$'\t' -t \
      | awk 'NR<2{print $0;next}{print $0 | "sort --key=2"}'
      # | awk '{printf "\033[1;32m%s\t\033[01;38;5;95;38;5;196m%s\t\033[00m\033[1;34m%s\t\033[01;90m%s %s %s %s %s %s %s\033[00m\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10;}' \
}


function docker-php-composer() {
  docker run -it --rm \
    -v $(pwd):/var/www/html \
    -w /var/www/html \
    -it \
    composer:latest \
    --ignore-platform-req=ext-gd --ignore-platform-req=ext-intl "$@" 
}

function docker-php-exec() {
  docker run -it --rm \
    -v $(pwd):/var/www/html \
    -w /var/www/html \
    -it \
    composer:latest \
    php "$@" 
}

function docker-nodejs() {
  docker run -it --rm \
    -v $(pwd):/app \
    -w /app \
    --entrypoint sh \
    node:18-alpine \
    -c "$@"
}

function docker-stop() {
  containers=$(docker ps --format "{{.ID}}:{{.Names}}")
  for container in $containers
  do
      IFS=':' read -r id name <<< "$container"
      echo "Container ID: $id, Name: $name"
      read -p "Do you want to stop this container? (y/n) " answer
      if [ "$answer" == "y" ]; then
          docker stop $id
          echo "Container $id ($name) stopped."
      else
          echo "Skipping container $id ($name)."
      fi
  done
}

function docker-cleanup() {
  docker builder prune -a 
  docker image prune -a
  docker system prune
}

function gopass-set-env-from-secret() {
  if [ -z "$1" ]; then echo "Usage: gopass-set-env-from-secret <gopass-path-to-key-value-secret>"; fi
  eval $(gopass cat $1 2>/dev/null | grep -v '^#' | xargs)
  #eval $(gopass cat $1)
}


function git-setup() {
  git config --global user.name $(whoami)
  git config --global user.email $(whoami)@$(hostname)
  git config --global init.defaultBranch master
  git config --global --add --bool push.autoSetupRemote true
}

function strip-comments() {
    local filename=$1

    if [ ! -f "$filename" ]; then
        echo "File not found: $filename"
        exit 1
    fi

    # Remove comments and empty lines
    cat $filename | sed 's|/*/,|*/|d' | sed 's|/|.*/|g' | sed 's|#.*||g' | sed '/^$/d'
    # # Remove // style comments
    # # Remove /* */ style comments
    # sed -e ':a' -e 's/\/\*[^*]*\*\///;ta' -e 's/\/\*.*//g' -e 's/.*\*\///g' \
}

# Function to generate a random string without special characters
function random-string() {
  tr -dc 'a-zA-Z0-9_\-%*!' < /dev/urandom | head -c "${1:-16}" # 16 chars by default
  echo
}

function random-base64() {
    head -c${1:-32} /dev/urandom | base64   # 32 chars by default
}

function init-dotfiles-adopt() {
  DD="$HOME/.mount/dotfiles_priv"
  if [ ! -d $DD ]; then
    DD="/workspaces/.mount/dotfiles_priv"
  fi

  if [ -d $DD ]; then
    echo "Bootstraping files in $DD"
    # Create neccessary directories
    mkdir -p $DD/.terraform.d/
    mkdir -p $DD/.aws/
    mkdir -p $DD/.kube/

    # Touch files
    touch $DD/.terraform.d/credentials.tfrc.json
    touch $DD/.bash_history
    touch $DD/.zsh_history
    stow -d $(dirname $DD) --adopt dotfiles_priv -t $HOME
  else
    echo "ERROR: Could not determine the dotfiles_priv directory"
    return 1;
  fi
}

#
# HELP/KB
#

function help-kb() {
  cat <<EOF
  Use the following commands to get help on a specific topic:

  help-kb-tmux
  help-kb-git
  help-kb-vim
  help-kb-vscode
EOF
}

function help-kb-vim() {
  cat <<EOF
  *** VIM shortcuts/motions/...***
  qa<motion>q @a  - start recording macro as identifier. q to sop recording, Run with @ afterwards
  */# - search next/previous occurance of the current word
  & - repeat last substitution (s:/foo/bar)
  % - jump between brackets (){}
  yiw - yank whole word
  vi - select (w/p)
  viwp - select (viw) and paste register
  {/} - jump to prev/next empty line
EOF
}

function help-kb-vscode-bindings() {
  cat <<EOF
  Advise to remove the following (WIP): 
  vim-mode: ctrl+p
  vim-mode: ctrl+c - scroll down by line without moving cursor - (overlap with jump to file popup)
EOF
}

function help-kb-vscode() {
  cat <<EOF

  * ctlr+] - go to definition
  * { } - got to prev/next empty line
EOF

  echo "viscode settings:"
  cat <<EOF
	"settings": {
		"keybindings": [
			{ "key": "ctrl+shift+u", "command": "sfdx.force.source.push" },
			{ "key": "cmd+e", "command": "workbench.files.action.showActiveFileInExplorer" }
		],
		"explorer.autoReveal": "focusNoScroll"
	}
EOF
}

function help-kb-tmux() {
  echo -e "${YELLOW}Key Bindings:${RESET}"
  echo -e "  ${PURPLE}Screen${RESET}    |  ${CYAN}Tmux ${RESET}     |  ${GREEN}Common Description${RESET}"
  echo -e "  ${PURPLE}---------${RESET} |  ${CYAN}---------${RESET} |  ${GREEN}------------------------${RESET}"
  echo -e "  ${PURPLE}Ctrl-a c${RESET}  |  ${CYAN}Ctrl-b c${RESET}  |  Create a new window"
  echo -e "  ${PURPLE}Ctrl-a a${RESET}  |  ${CYAN}Ctrl-b ,${RESET}  |  Rename a new window"
  echo -e "  ${PURPLE}Ctrl-a n${RESET}  |  ${CYAN}Ctrl-b n${RESET}  |  Switch to the next window"
  echo -e "  ${PURPLE}Ctrl-a p${RESET}  |  ${CYAN}Ctrl-b p${RESET}  |  Switch to the previous window"
  echo -e "  ${PURPLE}Ctrl-a S${RESET}  |  ${CYAN}Ctrl-b %${RESET}  |  Split the current region/horizontal pane"
  echo -e "  ${PURPLE}Ctrl-a | ${RESET} |  ${CYAN}Ctrl-b \"${RESET}  |  Split the current region/vertical pane"
  echo -e "  ${PURPLE}Ctrl-a d${RESET}  |  ${CYAN}Ctrl-b d${RESET}  |  Detach from the current session"
  echo -e "  ${PURPLE}Ctrl-a [${RESET}  |  ${CYAN}Ctrl-b [${RESET}  |  Enter copy mode (to scroll)"
  echo -e "  ${PURPLE}Ctrl-a ]${RESET}  |  ${CYAN}Ctrl-b ]${RESET}  |  Paste the copied text"
  echo -e "  ${PURPLE}Ctrl-a ?${RESET}  |  ${CYAN}Ctrl-b ?${RESET}  |  Show key bindings"
  echo -e "  ${PURPLE}Ctrl-a :${RESET}  |  ${CYAN}Ctrl-b :${RESET}  |  Enter command prompt"
  echo -e "  ${PURPLE}Ctrl-a a${RESET}  |  ${CYAN}Ctrl-b ,${RESET}  |  Rename window"
}

function help-kb-git() {
  cat <<EOF
  Git Snippets:
  git checkout <branch> -- <file>       # Checkout file from another branch:
  git stash push --keep-index <file>    # Stash single file keeping it
  git stash push -- <file>
  git diff --name-only <branch>         # List files changed between branches
  git diff <branch> -- <file>          # Show changes in a file between branches
  git diff branch_name1..branch_name2 -- path/to/file
  git push <remote> <local_branch>[:<remote_branch>]
  git branch --set-upstream-to=origin/<branch> <branch> - set branch name to map in remote

EOF
}

