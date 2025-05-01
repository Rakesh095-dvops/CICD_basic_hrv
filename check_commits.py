# Import after installing
import os
import requests
import sys
import json
# Importing dotenv to load environment variables from a .env file
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
REPO_OWNER = os.getenv("REPO_OWNER")
REPO_NAME = os.getenv("REPO_NAME")
BRANCH = os.getenv("BRANCH", "main")  # Default to 'main' if not specified

# GitHub API URL to get latest commit
url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/commits/{BRANCH}"

headers = {
    "Authorization": f"Bearer {GITHUB_TOKEN}",
    "Accept": "application/vnd.github+json",
}
#check latest commit
def check_latest_commit():
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        commit_data = response.json()
        #print(commit_data)
        latest_sha = commit_data['sha']
        commit_message = commit_data['commit']['message']
        print(f"Latest commit SHA: {latest_sha}")
        print(f"Commit message: {commit_message}")
    else:
        print(f"Failed to fetch latest commit. Status Code: {response.status_code}")
        print(response.json())
        sys.exit(1)


def main():
    LAST_COMMIT_FILE = '/tmp/last_commit.txt'
    latest_commit = check_latest_commit()
    if os.path.exists(LAST_COMMIT_FILE):
        with open(LAST_COMMIT_FILE, 'r') as f:
            last_commit = f.read().strip()

        if last_commit == latest_commit:
            print("No new commits.")
            return
        else:
            print("New commit detected!")
    else:
        print("First run, recording commit.")

    # Save latest commit
    with open(LAST_COMMIT_FILE, 'w') as f:
        f.write(latest_commit)

    # Trigger deployment
    os.system("/home/ubuntu/deploy.sh")
    
if __name__ == "__main__":
    main()
    check_latest_commit()