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

    const HATCHY = await ethers.getContractFactory("HATCHY");

    const hatchy = await HATCHY.attach("0x502580fc390606b47FC3b741d6D49909383c28a9");
    // await hatchy.deployed();
    console.log("deployed: hatchy")

    const HatchyGen1Staking = await ethers.getContractFactory("HatchyGen1Staking");
    // args:
    // _hatchyNft
    // _feeAddress
    // _signer
    const hatchyGen1Staking = await HatchyGen1Staking.attach("0x4ECD8615858810fA53f1Fed212856Ed973876956")
    // const hatchyGen1Staking = await upgrades.deployProxy(HatchyGen1Staking, [
    //     "0x76dAAaf7711f0Dc2a34BCA5e13796B7c5D862B53",
    //     "0xb6bE6C8EcA047e1fc0d3C6a5872B009272D0829e",
    //     "0x9D61113250007373fb605d18571AD85c8617fA7b"]);
    // await hatchyGen1Staking.deployed();
    // console.log("deployed: hatchyGen1Staking")

    const HatchyPocketGen2 = await ethers.getContractFactory("HatchyPocketGen2");
    const hatchyPocketGen2 = await HatchyPocketGen2.attach("0x7b6121b5B97b9945CE8528f37263bc01cA0B1826")
        // const hatchyPocketGen2 = await upgrades.deployProxy(HatchyPocketGen2, [
        // "https://hatchypocket.com/api/metadata/gen2/"]);
    // await hatchyPocketGen2.deployed();
    // tx = await hatchyPocketGen2.initialize1({gasLimit: "3000000"});
    // await tx.wait(2);
    // console.log('initialize1')
    // tx = await hatchyPocketGen2.initialize2({gasLimit: "3000000"});
    // await tx.wait(2);
    // console.log('initialize2')
    // tx = await hatchyPocketGen2.initialize3({gasLimit: "3000000"});
    // await tx.wait(2);
    // console.log('initialize3')
    // tx = await hatchyPocketGen2.initialize4({gasLimit: "3000000"});
    // await tx.wait(2);
    // console.log('initialize4')
    // tx = await hatchyPocketGen2.initialize5({gasLimit: "3000000"});
    // await tx.wait(2);
    // console.log('initialize5')
    // tx = await hatchyPocketGen2.initialize6({gasLimit: "3000000"});
    // await tx.wait(2);
    // // console.log('initialize6')

    // tx = await hatchyPocketGen2.flipState()
    // await tx.wait(2)


    const HatchyPocketEggs = await ethers.getContractFactory("HatchyPocketEggs");
    const hatchyPocketEggs = await HatchyPocketEggs.attach("0x956062f3299ADEB15A8676426542e1F0c0E7ca09")
        
    //     const hatchyPocketEggs = await upgrades.deployProxy(HatchyPocketEggs, [
    //     "https://hatchypocket.com/api/metadata/egg/", 
    //     ethers.utils.parseEther("2000"), hatchy.address]);
    // await hatchyPocketEggs.deployed();

    // tx = await hatchyPocketEggs.setHatchyGen2(hatchyPocketGen2.address)
    // await tx.wait(2)

    // tx = await hatchyPocketGen2.setEggContract(hatchyPocketEggs.address);
    // await tx.wait(2);
    // console.log('egg: set gen2 address')

    const HatchyGen2Staking = await ethers.getContractFactory("HatchyGen2Staking");
    const hatchyGen2Staking = await upgrades.deployProxy(HatchyGen2Staking, [
        hatchyPocketGen2.address
    ]);
    await hatchyGen2Staking.deployed();
    console.log("deployed: hatchyGen2Staking")
    console.log(hatchyGen2Staking.address)

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
    console.log(hatchyReward.address)
    // let bal = await hatchy.balanceOf(process.env.DEPLOYMENT_ACCOUNT_ADDRESS);
    tx = await hatchy.transfer(hatchyReward.address,  ethers.utils.parseEther("600000000"), {gasLimit: "1000000"});
    await tx.wait(2);
    console.log("balance: hatchyReward")

    tx = await hatchyGen1Staking.setRewarder(hatchyReward.address);
    await tx.wait(2)
    console.log("staking gen 1: set hatchyReward")

    tx = await hatchyGen2Staking.setRewarder(hatchyReward.address);
    await tx.wait(2)
    console.log("staking gen 2: set hatchyReward")


    fs.writeFileSync("./deployed-mainnet.json", JSON.stringify({
        hatchyPocketGen1: "0x76dAAaf7711f0Dc2a34BCA5e13796B7c5D862B53",
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
