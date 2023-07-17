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
