#!/bin/zsh

########################################
########## NOTES ON USEAGE #############
########################################
## normal usage
#### ./git-shmancy.sh

## verbose mode (shows debug messages)
#### ./git-shmancy.sh -v

## quiet mode (shows only errors)
#### ./git-shmancy.sh -q

## extra verbose mode
#### ./git-shmancy.sh --verbose
########################################
########################################

# Parse command line options
zparseopts -D -E -- v=verbose -verbose=verbose q=quiet -quiet=quiet

# Verbosity levels
VERBOSE=${#verbose}
QUIET=${#quiet}

# Progress bar function with better spacing and full lolcat support
progress_bar() {
    local current=$1
    local total=$2
    local title=$3
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))

    echo # Add spacing before progress bar
    printf "\r${title}\n" | lolcat
    printf "\r[" | lolcat
    printf "%${completed}s" | tr ' ' '=' | lolcat
    printf "%${remaining}s" | tr ' ' ' '
    printf "] %d%%\n" "${percentage}" | lolcat
    echo # Add spacing after progress bar
}

# Verbose logging function
log() {
    local level=$1
    shift
    case $level in
        "INFO")
            [[ $QUIET -eq 0 ]] && echo "ℹ️  $*" | lolcat
            ;;
        "DEBUG")
            [[ $VERBOSE -gt 0 ]] && echo "🔍 $*" | lolcat
            ;;
        "ERROR")
            echo "❌ $*" | lolcat >&2
            ;;
        "SUCCESS")
            [[ $QUIET -eq 0 ]] && echo "✅ $*" | lolcat
            ;;
    esac
}

# Check for required commands and install if missing
check_and_install() {
    local cmd=$1
    if ! command -v $cmd &> /dev/null; then
        log "INFO" "📦 $cmd is not installed. Installing..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install $cmd
            log "SUCCESS" "$cmd installed successfully"
        else
            log "ERROR" "Please install $cmd manually. Brew only supported on macOS."
            exit 1
        fi
    fi
}

# Initialize progress counter
TOTAL_STEPS=9
current_step=0

# Check dependencies
log "INFO" "Checking dependencies..."
echo # Add spacing
for cmd in git lolcat fzf cursor jq; do
    check_and_install $cmd
    ((current_step++))
    progress_bar $current_step $TOTAL_STEPS "Setting up dependencies"
done

# Function to print pretty headers
print_header() {
    echo $1 | lolcat -a -d 50
    echo "===============================================" | lolcat -a -d 50
}

# Function to get GitHub username
get_github_user() {
    github_user=$(git config --get user.name)
    github_email=$(git config --get user.email)
    echo "Author: $github_user <$github_email>"
}

# 1. Get git status
((current_step++))
progress_bar $current_step $TOTAL_STEPS "Checking git status"
print_header "Current Git Status"
changes=$(git status --porcelain)
log "DEBUG" "Found $(echo "$changes" | wc -l) changed files"

# 2. Create option-based file selection
if [ -z "$changes" ]; then
    log "ERROR" "No changes to commit!"
    exit 0
fi

print_header "Select Changes to Commit"
IFS=$'\n' change_array=("${(f)changes}")
selected_files=()

echo "$changes" | \
    awk '{printf "[%d] %-60s %s\n", NR-1, substr($0,4), $1}' | \
    lolcat

vared -p "Enter the numbers of the files to commit, separated by spaces: " -c selection

for index in ${(s: :)selection}; do
    selected_files+=("${change_array[$index]}")
done

if [ ${#selected_files[@]} -eq 0 ]; then
    log "ERROR" "No files selected!"
    exit 0
fi

# 3. Confirm selections
((current_step++))
progress_bar $current_step $TOTAL_STEPS "Confirming selection"
print_header "Selected Changes"
for file in "${selected_files[@]}"; do
    echo "$file" | lolcat
done
log "INFO" "\nProceed with these changes? (y/n)"
vared -p "Confirm (y/n): " -c confirm
if [[ $confirm != "y" ]]; then
    log "ERROR" "Operation cancelled!"
    exit 0
fi

# 4. Get commit message
((current_step++))
progress_bar $current_step $TOTAL_STEPS "Creating commit message"
print_header "Commit Message"
vared -p "Enter a brief commit message: " -c commit_message

# 5. Get detailed commit message
((current_step++))
progress_bar $current_step $TOTAL_STEPS "Creating detailed description"
print_header "Detailed Description (optional)"
echo "Enter a detailed description (press Ctrl+D when done):"
detailed_message=$(cat)

# Stage and commit selected files
for change in "${selected_files[@]}"; do
    file=$(echo "$change" | sed 's/^...//')
    git add "$file"
done

# Commit with message and description
((current_step++))
progress_bar $current_step $TOTAL_STEPS "Committing changes"
if [ -n "$detailed_message" ]; then
    git commit -m "$commit_message" -m "$detailed_message"
else
    git commit -m "$commit_message"
fi

# 8. Push and create PR
((current_step++))
progress_bar $current_step $TOTAL_STEPS "Pushing to remote"
git push

# Create PR using GitHub CLI if available
if command -v gh &> /dev/null; then
    ((current_step++))
    progress_bar $current_step $TOTAL_STEPS "Creating PR"
    pr_body="$(get_github_user)

${commit_message}

${detailed_message}

Created: $(date '+%Y-%m-%d %H:%M:%S %Z')"

    gh pr create \
        --title "$commit_message" \
        --body "$pr_body" \
        --base trunk \
        --head "$(git rev-parse --abbrev-ref HEAD)"
fi

# 9. Print summary
((current_step++))
progress_bar $current_step $TOTAL_STEPS "Updating COMMITLOG"
print_header "Commit Summary"

# Create a pretty table using printf
printf "%-20s | %-40s\n" "Field" "Value" | lolcat
printf "%-20s-+-%-40s\n" "--------------------" "----------------------------------------" | lolcat
printf "%-20s | %-40s\n" "Branch" "$(git rev-parse --abbrev-ref HEAD)" | lolcat
printf "%-20s | %-40s\n" "Author" "$(get_github_user)" | lolcat
printf "%-20s | %-40s\n" "Timestamp" "$(date '+%Y-%m-%d %H:%M:%S %Z')" | lolcat
printf "%-20s | %-40s\n" "Commit Message" "$commit_message" | lolcat
if [ -n "$detailed_message" ]; then
    printf "%-20s | %-40s\n" "Details" "$(echo "$detailed_message" | head -n1)..." | lolcat
fi
printf "%-20s | %-40s\n" "Files Changed" "$(echo "$selected_files" | wc -l) files" | lolcat

echo -e "\nFiles committed:" | lolcat
for change in "${selected_files[@]}"; do
    file=$(echo "$change" | sed 's/^...//')
    echo "  - $file" | lolcat
done

# 10. Extract summary of latest commit to "COMMITLOG"
latest_commit=$(git log -1 --pretty=format:'%H')
author=$(git log -1 --pretty=format:'%an <%ae>')
branch=$(git rev-parse --abbrev-ref HEAD)
timestamp=$(git log -1 --pretty=format:'%ai')
version=$(git describe --tags --abbrev=0 2>/dev/null || echo "No version tag")
commit_msg=$(git log -1 --pretty=format:'%B')

# Format the summary
commit_summary=$(printf "Latest Changes Summary\n")
commit_summary+=$(printf "====================\n\n")
commit_summary+=$(printf "Author: %s\n" "$author")
commit_summary+=$(printf "Branch: %s\n" "$branch")
commit_summary+=$(printf "Timestamp: %s\n" "$timestamp")
commit_summary+=$(printf "Version: %s\n" "$version")
commit_summary+=$(printf "\nCommit Message:\n%s\n" "$commit_msg")
commit_summary+=$(printf "\nChanged Files:\n")
commit_summary+=$(git show --name-status $latest_commit | grep -E '^[AMDRC]' | sed 's/^/  /')

# Prepend the summary to COMMITLOG
echo -e "$commit_summary\n\n$(cat COMMITLOG)" > COMMITLOG

print_header "Done! 🎉"


# TODO:
# - Add option to see visual diff of changes
# - Fix the selection prompt and output
# - Make a more standard commitlog
# - Add a new "todo" file to track desired changes and push to a todo branch


# Fix Bugs:
# - When no changes are found, it doesn't exit 0
# - When there are no changes, it still opens the editor
# - Bad substitution error: ./scripts/git-shmancy.sh:124: bad substitution
# - Fix this: "To github.com:octokas/fluffybytes.git 03ad7f7..f23588e  feature/run-with-'cursor--'-to-read-from-stdin-(e.g.-'ps-aux-|-grep-code-|-cursor--').-20241127-1203 -> feature/run-with-'cursor--'-to-read-from-stdin-(e.g.-'ps-aux-|-grep-code-|-cursor--').-20241127-1203"
