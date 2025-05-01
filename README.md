# CI/CD Basic  Implementation 
__
## Introduction
Create a complete CI-CD pipeline using bash, python, and crontabs, AWS services
## Task 1: Set Up a Simple HTML Project 
-  Below mentioned git hub repo is a simple HTML project 
    ![alt text](images/0_initial_draft_website.png)
## Task 2: Set Up an AWS EC2/Local Linux Instance with Nginx
-  Set up a Basic AWS EC2 Setup with ``OS: Ubuntu 22.04 LTS (recommended)`` and run below mentioned script to install and configure nginx
```bash
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx
```
### AWS EC2 

-   ![EC2_setup](images/2_EC2_setup.png)
-   ![3_EC2_nginx_setup](images/3_EC2_nginx_setup.png)

### Nginx Home Page 

-   ![nginx home page](images/1_EC2_ngnix_homePage.png)

### Custom project set up 

- Create project directory

```bash
  sudo mkdir -p /var/www/proj
  sudo chown -R $USER:$USER /var/www/proj
  sudo mkdir -p /var/www/proj-temp
  sudo chown -R $USER:$USER /var/www/proj-temp
```


- Task 3: Write a Python Script to Check for New Commits
    - Create a Python script to check for new commits using the GitHub API.
- Task 4: Write a Bash Script to Deploy the Code
    - Create a bash script to clone the latest code and restart Nginx.
- Task 5: Set Up a Cron Job to Run the Python Script
    - Create a cron job to run the Python script at regular intervals.
- Task 6: Test the Setup 
    - Make a new commit to the GitHub repository and check that the changes are automatically deployed. 