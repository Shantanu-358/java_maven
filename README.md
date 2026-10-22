# Cloud Demo Java Application (Spring Boot)

A lightweight, production-ready Java Spring Boot application optimized for **AWS Free Tier (t2.micro / t3.micro)** Linux EC2 instances, designed to be built and deployed automatically via **Jenkins CI/CD**.

---

## 🚀 Application Overview

- **Framework**: Spring Boot 3.2.x (Java 17)
- **Packaging**: Executable Fat JAR (`target/app.jar`)
- **Key Features**:
  - Live Web Dashboard at `http://<EC2-IP>:8080/` with modern dark mode & glassmorphism UI.
  - REST Endpoints:
    - `GET /api/status`: Real-time JVM memory stats, instance hostname, OS details, and uptime.
    - `GET /api/health`: JSON health check endpoint.
    - `GET /actuator/health`: Standard Spring Boot Actuator status.
    - `GET /api/greet?name=DevOps`: Greeting endpoint with query parameter support.
  - JVM flags tuned for **low memory usage** (`-Xms128m -Xmx256m -XX:+UseSerialGC`) to avoid OOM errors on 1GB RAM EC2 instances.

---

## 📁 Repository Structure

```
├── pom.xml                 # Maven build definition & dependencies
├── .gitignore              # Standard Java / Maven ignore rules
├── scripts/
│   ├── setup-swap.sh       # Essential script to add 2GB swap on Free Tier EC2
│   ├── app.service         # Linux systemd service configuration
│   └── deploy.sh           # Safe deployment script with health check validation
├── src/
│   ├── main/
│   │   ├── java/com/example/demo/
│   │   │   ├── DemoApplication.java         # Spring Boot entry point
│   │   │   └── controller/ApiController.java # REST API endpoints
│   │   └── resources/
│   │       ├── application.properties       # App settings & Actuator exposure
│   │       └── static/                      # Web Dashboard (HTML, CSS, JS)
│   └── test/
│       └── java/com/example/demo/DemoApplicationTests.java # Context load test
└── README.md
```

---

## 💡 AWS Free Tier Architecture & Recommendations

AWS Free Tier includes:
- **750 hours per month** of `t2.micro` or `t3.micro` instances (1 vCPU, 1 GB RAM).
- **30 GB EBS General Purpose SSD** storage per month.

### Key Considerations for 1GB RAM Instances:
1. **The 750-Hour Limit**:
   - If you run **1 instance 24/7**, it uses ~720–744 hours per month (**100% covered under Free Tier**).
   - If you run **2 instances 24/7** (e.g., 1 for Jenkins + 1 for Production App), you consume ~1,440 hours and will be billed for the extra hours.
   - **Recommended Approach**:
     - *Cost-Free Option*: Run Jenkins and the Java app on a **single `t2.micro` instance**, using reverse proxy or separate ports (e.g., Jenkins on port `8080` with prefix or port `8888`, and the App on port `8080` or `5000`).
     - *Alternative*: If you use two separate `t2.micro` instances, stop the Jenkins instance when you are not actively practicing or building to stay within the 750 monthly free hours.
2. **Preventing Out Of Memory (OOM) Errors**:
   - Jenkins (Java JVM) and Maven build processes spike memory usage during compilation.
   - Running `sudo bash scripts/setup-swap.sh` will allocate a **2 GB Swap file** on your 30 GB EBS root volume. This prevents the Linux OOM Killer from terminating Jenkins or your build!

---

## 🛠️ Installing Jenkins & Java 17 on Linux EC2

### 1. Amazon Linux 2023

```bash
# Update system packages
sudo dnf update -y

# Setup 2GB Swap space (crucial for t2.micro)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab

# Install Java 17 (Amazon Corretto) & Git & Maven
sudo dnf install -y java-17-amazon-corretto-devel git maven

# Add Jenkins repository & install Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf install -y jenkins

# Configure Jenkins JVM memory (limit heap so it fits on t2.micro)
sudo sed -i 's/JAVA_OPTS="/JAVA_OPTS="-Xms256m -Xmx512m /' /usr/lib/systemd/system/jenkins.service

# Start and enable Jenkins service
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Retrieve initial administrator password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 2. Ubuntu 22.04 / 24.04 LTS

```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Setup Swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab

# Install OpenJDK 17, Git, and Maven
sudo apt install -y openjdk-17-jdk git maven

# Install Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install -y jenkins

# Limit Jenkins memory to prevent OOM
sudo sed -i 's/JAVA_OPTS="/JAVA_OPTS="-Xms256m -Xmx512m /' /lib/systemd/system/jenkins.service
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Retrieve initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## 🔒 AWS EC2 Security Group Configuration

In the AWS EC2 Management Console, edit **Inbound Rules** for your instance's Security Group:

| Type | Protocol | Port Range | Source | Purpose |
|------|----------|------------|--------|---------|
| SSH | TCP | 22 | Your IP / 0.0.0.0/0 | SSH terminal access |
| Custom TCP | TCP | 8080 | 0.0.0.0/0 | Jenkins UI or Java App |
| Custom TCP | TCP | 80 / 5000 | 0.0.0.0/0 | Optional app port or Nginx |

---

## 📦 Setting Up the App on the Production Server

1. **Install Java 17 Runtime**:
   ```bash
   # Amazon Linux 2023
   sudo dnf install -y java-17-amazon-corretto-headless
   # Ubuntu
   sudo apt install -y openjdk-17-jre-headless
   ```

2. **Configure App as a System Service**:
   ```bash
   sudo mkdir -p /opt/cloud-demo
   sudo cp scripts/app.service /etc/systemd/system/
   sudo systemctl daemon-reload
   ```

3. **Deploy Artifact**:
   ```bash
   sudo bash scripts/deploy.sh /path/to/target/app.jar
   ```

4. **Verify Service**:
   ```bash
   systemctl status app.service
   curl http://localhost:8080/api/health
   ```
