// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import * as dotenv from "dotenv"

dotenv.config();

import {ethers, upgrades, artifacts} from "hardhat";
import * as fs from 'fs'


async function main() {
    let tx;


    // deploy core nft

    const HatchyPockets = await ethers.getContractFactory("HatchyPockets")
    const hatchyContract = await HatchyPockets.deploy()

    tx = await hatchyContract.startDrop();
    await tx.wait(1)

    const HATCHY = await ethers.getContractFactory("HATCHY");

    const hatchy = await HATCHY.deploy();
    await hatchy.deployed();
    console.log("deployed: hatchy")

    const HatchyGen1Staking = await ethers.getContractFactory("HatchyGen1Staking");
    // args:
    // _hatchyNft
    // _feeAddress
    // _signer
    const hatchyGen1Staking = await upgrades.deployProxy(HatchyGen1Staking, [
        hatchyContract.address,
        "0x9D61113250007373fb605d18571AD85c8617fA7b",
        "0x9D61113250007373fb605d18571AD85c8617fA7b"]);
    await hatchyGen1Staking.deployed();
    console.log("deployed: hatchyGen1Staking")

    const HatchyPocketGen2 = await ethers.getContractFactory("HatchyPocketGen2");
    const hatchyPocketGen2 = await upgrades.deployProxy(HatchyPocketGen2, ["https://hatchypocket.com/api/gen2/"]);
    await hatchyPocketGen2.deployed();
    tx = await hatchyPocketGen2.initialize1({gasLimit: "3000000"});
    await tx.wait(2);
    console.log('initialize1')
    tx = await hatchyPocketGen2.initialize2({gasLimit: "3000000"});
    await tx.wait(2);
    console.log('initialize2')
    tx = await hatchyPocketGen2.initialize3({gasLimit: "3000000"});
    await tx.wait(2);
    console.log('initialize3')
    tx = await hatchyPocketGen2.initialize4({gasLimit: "3000000"});
    await tx.wait(2);
    console.log('initialize4')
    tx = await hatchyPocketGen2.initialize5({gasLimit: "3000000"});
    await tx.wait(2);
    console.log('initialize5')
    tx = await hatchyPocketGen2.initialize6({gasLimit: "3000000"});
    await tx.wait(2);
    console.log('initialize6')

    tx = await hatchyPocketGen2.flipState()
    await tx.wait(1)


    const HatchyPocketEggs = await ethers.getContractFactory("HatchyPocketEggs");
    const hatchyPocketEggs = await upgrades.deployProxy(HatchyPocketEggs, ["https://hatchypocket.com/api/gen2egg/", ethers.utils.parseEther("1"), hatchy.address]);
    await hatchyPocketEggs.deployed();

    tx = await hatchyPocketEggs.setHatchyGen2(hatchyPocketGen2.address)
    await tx.wait(1)

    tx = await hatchyPocketGen2.setEggContract(hatchyPocketEggs.address);
    await tx.wait(1);
    console.log('egg: set gen2 address')

    const HatchyGen2Staking = await ethers.getContractFactory("HatchyGen2Staking");
    const hatchyGen2Staking = await upgrades.deployProxy(HatchyGen2Staking, [hatchyPocketGen2.address]);
    await hatchyGen2Staking.deployed();
    console.log("deployed: hatchyGen2Staking")

    /*
    _rewardTokenAddress
    _hatchyGen1Stake
    _hatchyGen2Stake
    _rewardPerWeek*/
    const rewardPerWeek = ethers.utils.parseEther("2500000");
    const HatchyReward = await ethers.getContractFactory("HatchyReward");
    const hatchyReward = await upgrades.deployProxy(HatchyReward, [
        hatchy.address,
        hatchyGen1Staking.address,
        hatchyGen2Staking.address,
        rewardPerWeek
    ]);
    await hatchyReward.deployed();
    console.log("deployed: hatchyReward")
    // let bal = await hatchy.balanceOf(process.env.DEPLOYMENT_ACCOUNT_ADDRESS);
    tx = await hatchy.transfer(hatchyReward.address,  ethers.utils.parseEther("600000000"));
    await tx.wait(1);
    console.log("balance: hatchyReward")

    tx = await hatchyGen1Staking.setRewarder(hatchyReward.address);
    await tx.wait(1)
    console.log("staking gen 1: set hatchyReward")

    tx = await hatchyGen2Staking.setRewarder(hatchyReward.address);
    await tx.wait(1)
    console.log("staking gen 2: set hatchyReward")


    fs.writeFileSync("./deployed2.json", JSON.stringify({
        hatchyPocketGen1: hatchyContract.address,
        hatchyToken: hatchy.address,
        hatchyPocketGen2Eggs: hatchyPocketEggs.address,
        hatchyPocketGen2: hatchyPocketGen2.address,
        hatchyGen1Staking: hatchyGen1Staking.address,
        hatchyGen2Staking: hatchyGen2Staking.address,
        hatchyReward: hatchyReward.address
    }))


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
