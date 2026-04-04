import * as pulumi from "@pulumi/pulumi";
import * as azure from "@pulumi/azure";
import * as fs from "fs";

const config = new pulumi.Config();
const dbPassword = config.requireSecret("dbPassword");
const publicKey = config.require("publicKey");

const resourceGroup = new azure.core.ResourceGroup("kiwitcms-rg", {
    location: "East US",
});

const network = new azure.network.VirtualNetwork("kiwitcms-vnet", {
    resourceGroupName: resourceGroup.name,
    location: resourceGroup.location,
    addressSpaces: ["10.0.0.0/16"],
});

const subnet = new azure.network.Subnet("kiwitcms-subnet", {
    resourceGroupName: resourceGroup.name,
    virtualNetworkName: network.name,
    addressPrefixes: ["10.0.1.0/24"],
});

const publicIp = new azure.network.PublicIp("kiwitcms-ip", {
    resourceGroupName: resourceGroup.name,
    location: resourceGroup.location,
    allocationMethod: "Dynamic",
});

const networkInterface = new azure.network.NetworkInterface("kiwitcms-nic", {
    resourceGroupName: resourceGroup.name,
    location: resourceGroup.location,
    ipConfigurations: [{
        name: "kiwitcms-nic-config",
        subnetId: subnet.id,
        privateIpAddressAllocation: "Dynamic",
        publicIpAddressId: publicIp.id,
    }],
});

const dockerCompose = fs.readFileSync("../../docker-compose.yml", "utf8");

const userData = pulumi.interpolate`#!/bin/bash
apt-get update
apt-get install -y docker.io docker-compose-plugin
systemctl start docker
systemctl enable docker
mkdir -p /home/adminuser/kiwitcms
cat <<EOT > /home/adminuser/kiwitcms/docker-compose.yml
${dockerCompose}
EOT
cat <<EOT > /home/adminuser/kiwitcms/.env
KIWI_DB_PASSWORD=${dbPassword}
KIWI_DB_HOST=db
KIWI_DB_NAME=kiwitcms
KIWI_DB_USER=kiwitcms
EOT
chown -R adminuser:adminuser /home/adminuser/kiwitcms
cd /home/adminuser/kiwitcms
docker compose up -d
`;

const vm = new azure.compute.LinuxVirtualMachine("kiwitcms-vm", {
    resourceGroupName: resourceGroup.name,
    location: resourceGroup.location,
    size: "Standard_B1s",
    adminUsername: "adminuser",
    networkInterfaceIds: [networkInterface.id],
    adminSshKeys: [{
        username: "adminuser",
        publicKey: publicKey,
    }],
    osDisk: {
        caching: "ReadWrite",
        storageAccountType: "Standard_LRS",
    },
    sourceImageReference: {
        publisher: "Canonical",
        offer: "0001-com-ubuntu-server-focal",
        sku: "20_04-lts",
        version: "latest",
    },
    userData: userData.apply(ud => Buffer.from(ud).toString('base64')),
});

export const publicIpAddress = vm.publicIpAddress;
