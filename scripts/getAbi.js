const fs = require("fs");
const path = require("path");

const getTheAbi = (name) => {
  try {
    const dir = path.resolve(__dirname, `../artifacts/contracts/${name}.sol/${name}.json`);
    const file = fs.readFileSync(dir, "utf8");
    const json = JSON.parse(file);
    const abi = json.abi;

    console.log(`abi`, abi);

    // Save the ABI to a new JSON file at the root
    const abiFilePath = path.resolve(__dirname, `../abi/${name}-abi.json`);
    fs.writeFileSync(abiFilePath, JSON.stringify(abi, null, 2));

    return abi;
  } catch (e) {
    console.log(`e`, e);
  }
};

getTheAbi("PrivatePool");