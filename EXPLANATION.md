# Week 4 IP 2 Creating a Basic Micro-service

# 1. Choice of the base image on which to build each container.
- The Client and Backend applications were based on Node so I used node:16-alpine as the base image for both. Build the client app and served it using Nginx based on nginx:1.21.0-alpine image.
- For Mongo DB the latest version of Mongo DB image was used. 
- Alpine image versions of node and nginx to reduce the size of my built images.
# 2. Dockerfile directives used in the creation and running of each container.
## Client Container
- `FROM node:16-alpine as builder` - Use Node 16 alpine as base image
- `WORKDIR /app` - Set the working directory to /app inside the container
- `COPY . .` - Copy all files to the working directory
- `RUN npm install` - Install dependancies 
- `RUN npm run build` - Build the application
- `FROM nginx:1.21.0-alpine as production` - user Nginx as base image
- `ENV NODE_ENV production` - Set the node enviroment to production
- `COPY --from=builder /app/build /usr/share/nginx/html` - copy the build folder in /app to the root of the nginx webserver
- `COPY nginx.conf /etc/nginx/conf.d/default.conf` - copy the nginx configuration 
- `EXPOSE 80` - Expose port 80 
- `CMD ["nginx", "-g", "daemon off;"]` - Command to run when container starts

## Backend Container
- `FROM node:16-alpine` - Use Node 16 alpine as base image
- `WORKDIR /app` - Set the working directory to /app inside the container
- `COPY package.json package.json` - Copy the package.json to the working directory
- `RUN npm install` - Intall dependancies
- `COPY . .` - Copy all the app files to the working directory
- `EXPOSE 5000` - Expose port 5000 to allow connection to the app.
- `CMD [ "npm", "start" ]` - Run npm start command when the container starts

# 3. Docker-compose Networking (Application port allocation and a bridge network implementation) where necessary.
- A bridge network was defined and attached to all the services to facilitate inter container communication.
```
networks:
    ip-network:
        driver: bridge
```
#### Port mapping 
- Client 
```
ports:
    - 8081:80
```
- Backend
```
ports:
    - 5000:5000
```

# 4. Docker-compose volume definition and usage (where necessary).
- A volume was used to persist the mongodb data
```
volumes:
  mongodb_data:
```
- Usage
```
  mongodb:
    image: mongo
    restart: always
    volumes:
      - mongodb_data:/data/db
    networks:
      - ip-network
```
# 5. Git workflow used to achieve the task.
- Git was used to clone the application, commit changes after significant milestones were reached, revert to previous commit when some changes did not work as expected.
# 6. Successful running of the applications and if not, debugging measures applied.
- The application was successfully run using `docker compose up -d` and incase of any issues I used `docker logs [container-name]` to view the container logs for debugging purposes.

# 7. Good practices such as Docker image tag naming standards for ease of identification of images and containers. 
- The built containers were named and tagged using descriptive names and semantic versioning.

### Frontend 
```
  frontend:
    build:
      context: ./client
      dockerfile: Dockerfile
      tags:
        - elkingsparx/ip2-client:1.0.1
    container_name: frontend-container
```

### Backend
```
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
      tags:
        - elkingsparx/ip2-backend:1.0.1
    container_name: backend-container
```
# Week 6 IP 3 - Stage 1 Using Vagrant and Ansible to deploy our application on docker.

## Vagrant Configuration
Vagrant is an open-source tool developed by HashiCorp that allows developers to create, configure, and manage virtualized development environments in a consistent and automated way. It provides an easy-to-use command-line interface (CLI) and a simple, declarative configuration file to define the characteristics of the virtual environment

- To initialize vagrant run the command `vagrant init`.This will create a Vagrantfile where you can define the configuration of your virtual machine.

```
Vagrant.configure("2") do |config|
  config.vm.box = "geerlingguy/ubuntu2004"
  
  config.vm.network "private_network", type: "dhcp"
  config.vm.network "forwarded_port", guest: 8081, host: 8081
  config.vm.network "forwarded_port", guest: 5000, host: 5000

  config.vm.provision "ansible" do |ansible|
    ansible.compatibility_mode = "2.0"
    ansible.config_file = "ansible.cfg"
    ansible.playbook = "playbook.yaml"
  end
end
```
#### Explanation:
- The Vagrant configuration begins with `Vagrant.configure("2") do |config|`, which defines the Vagrant version used in this configuration.

- `config.vm.box = "geerlingguy/ubuntu2004"` sets the base box to "geerlingguy/ubuntu2004," which means Vagrant will use this Ubuntu 20.04 image as the base for the virtual machine.

- The `config.vm.network` lines define the network configurations for the virtual machine. 
  - `config.vm.network "private_network", type: "dhcp"` sets up a private network with DHCP, which allows the virtual machine to have its IP address assigned dynamically.
  - `config.vm.network "forwarded_port", guest: 8081, host: 8081` forwards port 8081 from the guest (virtual machine) to port 8081 on the host (your local machine).
  - `config.vm.network "forwarded_port", guest: 5000, host: 5000` does the same but for port 5000.

- The `config.vm.provision "ansible" do |ansible|` block specifies Ansible as the provisioning tool for the virtual machine.

- `ansible.compatibility_mode = "2.0"` sets the compatibility mode for Ansible to version 2.0. This ensures that the Ansible playbook is executed with the appropriate settings.

- `ansible.config_file = "ansible.cfg"` specifies the path to the Ansible configuration file, if any.

- `ansible.playbook = "playbook.yaml"` sets the path to the Ansible playbook that will be executed during provisioning.

In summary, this Vagrant configuration creates a virtual machine based on the "geerlingguy/ubuntu2004" box, sets up a private network with DHCP, and forwards ports 8081 and 5000 from the guest to the host. It then uses Ansible as the provisioner to run the specified Ansible playbook, "playbook.yaml," inside the virtual machine.

### Ansible Playbook

An Ansible playbook is a file written in YAML format that defines a set of tasks, configurations, and steps to be executed on remote hosts. Ansible playbooks allow you to define the desired state of your infrastructure and automate the deployment and configuration of systems, applications, and services.

Each playbook consists of one or more plays, and each play contains a list of tasks. A task is a single unit of work that Ansible performs on a remote host. The tasks in a playbook are executed in order, and Ansible ensures that the desired state is achieved on each host.

```
---
- name: Deploy Yolo App using Vagrant
  gather_facts: true
  hosts: all
  become: true

  roles:
    - git-clone-yolo

  tasks:
    - name: Check if Docker is installed
      command: docker --version
      ignore_errors: true
      register: docker_check
      tags: docker

    - name: Install Docker Community Edition
      block:
        - name: Include Docker Setup Role
          include_role:
            name: docker-setup
      when: docker_check.rc != 0
      tags: docker

    - name: Run Docker Compose
      command: docker compose up -d
      args:
        chdir: /home/vagrant/yolo/
      tags: docker-compose
```


