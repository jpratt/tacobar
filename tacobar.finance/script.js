const Web3Modal = window.Web3Modal.default;
const WalletConnectProvider = window.WalletConnectProvider.default;
const evmChains = window.evmChains;

// Web3modal instance
let web3Modal;

// Chosen wallet provider given by the dialog window
let provider;

// Address of the selected account
let selectedAccount;

//Declare contract;
let contract, userInfo, web3;

function initWeb3Modal() {
  // Create the Web3Modal object
  web3Modal = new Web3Modal({
    network: "ropsten",
    cacheProvider: true,
    providerOptions: {
      //   walletconnect: {
      //     package: WalletConnectProvider,
      //     options: {
      //       infuraId: "b9d7b8d8c9f64f4c8d4f6c8e6b8a6b9b",
      //     },
      //   },
    },
  });
}

async function fetchAccountData() {
  web3 = new Web3(provider);
  const accounts = await web3.eth.getAccounts();
  selectedAccount = accounts[0];
  console.log(selectedAccount);

  contract = new web3.eth.Contract(contract_abi, contract_address);

  const accountBalance = await web3.eth.getBalance(selectedAccount);
  const contractBalance = await web3.eth.getBalance(contract_address);
  const rewards = await contract.methods
    .getAddSalsaSharedReward(selectedAccount)
    .call();
  userInfo = await contract.methods.getUserInfo(selectedAccount).call();

  console.log(userInfo, rewards);
  const tokenBalance = userInfo._userDeposit;

  $("#account-balance").text(
    Number(web3.utils.fromWei(accountBalance.toString(), "ether")).toFixed(2)
  );
  $("#contract-balance").text(
    Number(web3.utils.fromWei(contractBalance.toString(), "ether")).toFixed(2)
  );
  $("#token-balance").text(
    Number(web3.utils.fromWei(tokenBalance.toString(), "ether")).toFixed(2)
  );
  $("#rewards").text(web3.utils.fromWei(rewards.toString(), "ether"));
}

async function refreshAccountData() {
  $("#btn-connect").css("display", "none");
  $("#btn-disconnect").css("display", "block");

  await fetchAccountData(provider);
}

async function onConnect() {
  console.log("Opening a dialog", web3Modal);
  try {
    provider = await web3Modal.connect();
  } catch (e) {
    console.log("Could not get a wallet connection", e);
    return;
  }

  // Subscribe to accounts change
  provider.on("accountsChanged", (accounts) => {
    fetchAccountData();
  });

  // Subscribe to chainId change
  provider.on("chainChanged", (chainId) => {
    fetchAccountData();
  });

  // Subscribe to networkId change
  provider.on("networkChanged", (networkId) => {
    fetchAccountData();
  });

  await refreshAccountData();
}

async function onDisconnect() {
  if (provider.close) {
    await provider.close();
    await web3Modal.clearCachedProvider();
    provider = null;
  }
  selectedAccount = null;

  //update the UI
  $("#btn-connect").css("display", "block");
  $("#btn-disconnect").css("display", "none");
}

async function onAddSalsa() {
  if (contract) {
    const val = $("#input-add-salsa").val();
    console.log(val);
    try {
      await contract.methods.AddSalsa_Deposit().send({
        from: selectedAccount,
        value: web3.utils.toWei(val, "ether"),
      });
    } catch (error) {
      console.log(error);
    }
  } else {
    const modal = new bootstrap.Modal(".modal", {
      backdrop: true,
      keyboard: true,
      focus: true,
    });
    modal.toggle();
  }
}

async function onHireAbuelas() {
  if (contract) {
    const refAddress = "0x0000000000000000000000000000000000000000";
    try {
      await contract.methods.hireAbuelas(refAddress).send({
        from: selectedAccount,
        value: val,
      });
    } catch (error) {
      console.log(error);
    }
  } else {
    const modal = new bootstrap.Modal(".modal", {
      backdrop: true,
      keyboard: true,
      focus: true,
    });
    modal.toggle();
  }
}

$(document).ready(function () {
  initWeb3Modal();
  $("#btn-connect").click(onConnect);
  $("#btn-disconnect").click(onDisconnect);
  $("#add-salsa").click(onAddSalsa);
});
