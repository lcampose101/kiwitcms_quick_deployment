import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as fs from "fs";

const config = new pulumi.Config();
const dbPassword = config.requireSecret("dbPassword");
const amiId = config.require("amiId");
const keyName = config.require("keyName");

const group = new aws.ec2.SecurityGroup("kiwitcms-sg", {
    ingress: [
        { protocol: "tcp", fromPort: 22, toPort: 22, cidrBlocks: ["0.0.0.0/0"] },
        { protocol: "tcp", fromPort: 80, toPort: 80, cidrBlocks: ["0.0.0.0/0"] },
        { protocol: "tcp", fromPort: 443, toPort: 443, cidrBlocks: ["0.0.0.0/0"] },
    ],
    egress: [
        { protocol: "-1", fromPort: 0, toPort: 0, cidrBlocks: ["0.0.0.0/0"] },
    ],
});

const dockerCompose = fs.readFileSync("../../docker-compose.yml", "utf8");

const userData = pulumi.interpolate`#!/bin/bash
apt-get update
apt-get install -y docker-compose-plugin
mkdir -p /home/ubuntu/kiwitcms
cat <<EOT > /home/ubuntu/kiwitcms/docker-compose.yml
${dockerCompose}
EOT
cat <<EOT > /home/ubuntu/kiwitcms/.env
KIWI_DB_PASSWORD=${dbPassword}
KIWI_DB_HOST=db
KIWI_DB_NAME=kiwitcms
KIWI_DB_USER=kiwitcms
EOT
cd /home/ubuntu/kiwitcms
docker compose up -d
`;

const server = new aws.ec2.Instance("kiwitcms-server", {
    instanceType: "t3.micro",
    securityGroups: [group.name],
    ami: amiId,
    keyName: keyName,
    userData: userData,
});

export const publicIp = server.publicIp;
export const publicHostName = server.publicDns;
Line 1: 
The above content shows the entire, complete file contents of the requested file.
