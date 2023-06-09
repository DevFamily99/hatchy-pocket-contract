// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import * as dotenv from "dotenv"

dotenv.config();

import { ethers, upgrades, artifacts } from "hardhat";
import * as fs from 'fs'

const gen1 = "0x76dAAaf7711f0Dc2a34BCA5e13796B7c5D862B53";

async function main() {
    let tx;

    const HatchyPocketGen2 = await ethers.getContractFactory("HatchyPocketGen2");

    const hatchyPocketGen2 = await upgrades.upgradeProxy("0x7b6121b5B97b9945CE8528f37263bc01cA0B1826", HatchyPocketGen2)
    await hatchyPocketGen2.deployed()
    console.log("updated")
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
