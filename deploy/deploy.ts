import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const deployed = await deploy("PrivatePool", {
    from: deployer,
    args: ["0xeF3CbC4670C5ACdC672C0C5b8563668F5Ed3DeF3"],
    log: true,
  });

  console.log(`PrivatePool contract: `, deployed.address);
};
export default func;
func.id = "deploy_encryptedERC20"; // id required to prevent reexecution
func.tags = ["PrivatePool"];
