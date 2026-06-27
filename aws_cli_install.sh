sudo apt update -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt update
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install
echo "installing kubectl"
curl -LO https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl 
 
chmod +x kubectl 
 
sudo mv kubectl /usr/local/bin/
