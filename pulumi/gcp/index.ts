import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";
import * as fs from "fs";

const config = new pulumi.Config();
const dbPassword = config.requireSecret("dbPassword");
const sshPublicKey = config.require("sshPublicKey");
const sshUser = config.get("sshUser") || "kiwi";

const webFirewall = new gcp.compute.Firewall("web-firewall", {
    network: "default",
    allows: [
        { protocol: "tcp", ports: ["22", "80", "443"] },
    ],
    sourceRanges: ["0.0.0.0/0"],
});

const dockerCompose = fs.readFileSync("../../docker-compose.yml", "utf8");

const startupScript = pulumi.interpolate`#!/bin/bash
apt-get update
apt-get install -y docker.io docker-compose-plugin
systemctl start docker
systemctl enable docker
mkdir -p /home/${sshUser}/kiwitcms
cat <<EOT > /home/${sshUser}/kiwitcms/docker-compose.yml
${dockerCompose}
EOT
cat <<EOT > /home/${sshUser}/kiwitcms/.env
KIWI_DB_PASSWORD=${dbPassword}
KIWI_DB_HOST=db
KIWI_DB_NAME=kiwitcms
KIWI_DB_USER=kiwitcms
EOT
chown -R ${sshUser}:${sshUser} /home/${sshUser}/kiwitcms
cd /home/${sshUser}/kiwitcms
docker compose up -d
`;

const instance = new gcp.compute.Instance("kiwitcms-instance", {
    machineType: "e2-micro",
    bootDisk: {
        initializeParams: {
            image: "ubuntu-os-cloud/ubuntu-2004-lts",
        },
    },
    networkInterfaces: [{
        network: "default",
        accessConfigs: [{}], // Ephemeral IP
    }],
    metadataStartupScript: startupScript,
    metadata: {
        "ssh-keys": pulumi.interpolate`${sshUser}:${sshPublicKey}`,
    },
});

export const publicIp = instance.networkInterfaces[0].accessConfigs[0].natIp;
