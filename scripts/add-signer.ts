
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
const stakingContract = "0x0BAc5007a660D58E8E86e34F5E5Af2b7E2ca3b52";

const addressToAdd = "0x9D61113250007373fb605d18571AD85c8617fA7b";
async function main() {
    let tx;
    const HatchyGen1Staking = await ethers.getContractFactory("HatchyGen1Staking");
    const hatchyGen1Staking = HatchyGen1Staking.attach(stakingContract);
    console.log("deployed: hatchyGen1Staking")

    tx = await hatchyGen1Staking.addSignerRole(addressToAdd);
    await tx.wait(1)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});


