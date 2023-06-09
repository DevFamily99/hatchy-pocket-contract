// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import * as dotenv from "dotenv"

dotenv.config();

import {ethers, upgrades, artifacts} from "hardhat";
import * as fs from 'fs'

const gen1 = "0x76dAAaf7711f0Dc2a34BCA5e13796B7c5D862B53";

async function main() {
    let tx;
    // Deploy Navigator
    // const HATCHY = await ethers.getContractFactory("HATCHY");
    //
    // const hatchy = await HATCHY.deploy();
    // await hatchy.deployed();
    // console.log("deployed: hatchy")

    // const HatchyGen1Staking = await ethers.getContractFactory("HatchyGen1Staking");
    //
    // const hatchyGen1Staking = await upgrades.upgradeProxy("0xCDD3c0e911047B999f08DBeE09C9bbCc055C82a4", HatchyGen1Staking)
    // const HatchyGen2Staking = await ethers.getContractFactory("HatchyGen2Staking");
    //
    // const hatchyGen2Staking = await upgrades.upgradeProxy("0xA6465E0f285C0765829bb515Ca0343F4378C7Ca2", HatchyGen2Staking)
    //

    // const HatchyReward = await ethers.getContractFactory("HatchyReward");

    // const hatchyReward = upgrades.upgradeProxy("0x51A66e57e9142371896f14884BC5e743f722E333", HatchyReward)

    // console.log("updated")

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
