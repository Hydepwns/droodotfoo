/**
 * Web3 Wallet Hook
 *
 * Handles MetaMask wallet connection and message signing for authentication.
 * Communicates with Phoenix LiveView via pushEvent/handleEvent.
 */

import { ethers } from "ethers";

export const Web3WalletHook = {
  mounted() {
    console.log("[Web3] Hook mounted");

    this.provider = null;
    this.signer = null;
    this.address = null;
    this.chainId = null;

    // Listen for wallet connection request from server
    this.handleEvent("connect_wallet", async () => {
      console.log("[Web3] Connecting wallet...");
      await this.connectWallet();
    });

    // Listen for message signing request from server
    this.handleEvent("sign_message", async ({ message }) => {
      console.log("[Web3] Signing message...");
      await this.signMessage(message);
    });

    // Listen for wallet disconnect request from server
    this.handleEvent("disconnect_wallet", () => {
      console.log("[Web3] Disconnecting wallet...");
      this.disconnectWallet();
    });

    // Check if wallet is already connected on mount
    this.checkWalletConnection();

    // Listen for account and chain changes
    if (window.ethereum) {
      window.ethereum.on("accountsChanged", (accounts) => {
        console.log("[Web3] Accounts changed:", accounts);
        if (accounts.length === 0) {
          // Wallet disconnected
          this.handleWalletDisconnect();
        } else {
          // Account switched
          this.handleAccountSwitch(accounts[0]);
        }
      });

      window.ethereum.on("chainChanged", (chainId) => {
        console.log("[Web3] Chain changed:", chainId);
        // Reload page on chain change (recommended by MetaMask)
        window.location.reload();
      });
    }
  },

  destroyed() {
    console.log("[Web3] Hook destroyed");
    // Clean up event listeners
    if (window.ethereum) {
      window.ethereum.removeAllListeners("accountsChanged");
      window.ethereum.removeAllListeners("chainChanged");
    }
  },

  async checkWalletConnection() {
    if (!window.ethereum) {
      console.log("[Web3] MetaMask not detected");
      this.pushEvent("wallet_not_found", {});
      return;
    }

    try {
      // Check if already connected (without requesting connection)
      const accounts = await window.ethereum.request({
        method: "eth_accounts",
      });

      if (accounts.length > 0) {
        console.log("[Web3] Wallet already connected:", accounts[0]);
        this.provider = new ethers.BrowserProvider(window.ethereum);
        this.signer = await this.provider.getSigner();
        this.address = accounts[0];
        const network = await this.provider.getNetwork();
        this.chainId = Number(network.chainId);

        this.pushEvent("wallet_already_connected", {
          address: this.address,
          chainId: this.chainId,
        });
      }
    } catch (error) {
      console.error("[Web3] Error checking wallet connection:", error);
    }
  },

  async connectWallet() {
    if (!window.ethereum) {
      console.error("[Web3] MetaMask not installed");
      this.pushEvent("wallet_error", {
        message: "MetaMask not installed. Please install MetaMask to connect your wallet.",
      });
      return;
    }

    try {
      // Request account access
      this.provider = new ethers.BrowserProvider(window.ethereum);

      const accounts = await this.provider.send("eth_requestAccounts", []);

      if (accounts.length === 0) {
        throw new Error("No accounts found");
      }

      this.signer = await this.provider.getSigner();
      this.address = accounts[0];

      const network = await this.provider.getNetwork();
      this.chainId = Number(network.chainId);

      console.log("[Web3] Wallet connected:", {
        address: this.address,
        chainId: this.chainId,
      });

      this.pushEvent("wallet_connected", {
        address: this.address,
        chainId: this.chainId,
      });
    } catch (error) {
      console.error("[Web3] Error connecting wallet:", error);

      let message = "Failed to connect wallet";
      if (error.code === 4001) {
        message = "Connection request rejected by user";
      } else if (error.code === -32002) {
        message = "Connection request already pending. Please check MetaMask.";
      }

      this.pushEvent("wallet_error", { message });
    }
  },

  async signMessage(message) {
    if (!this.signer) {
      console.error("[Web3] No signer available");
      this.pushEvent("wallet_error", {
        message: "Wallet not connected",
      });
      return;
    }

    try {
      console.log("[Web3] Requesting signature for message:", message);

      const signature = await this.signer.signMessage(message);

      console.log("[Web3] Message signed:", signature);

      this.pushEvent("message_signed", {
        signature,
        address: this.address,
      });
    } catch (error) {
      console.error("[Web3] Error signing message:", error);

      let message = "Failed to sign message";
      if (error.code === 4001 || error.code === "ACTION_REJECTED") {
        message = "Signature request rejected by user";
      }

      this.pushEvent("signature_error", { message });
    }
  },

  disconnectWallet() {
    this.provider = null;
    this.signer = null;
    this.address = null;
    this.chainId = null;

    console.log("[Web3] Wallet disconnected");
    this.pushEvent("wallet_disconnected", {});
  },

  handleWalletDisconnect() {
    this.disconnectWallet();
  },

  async handleAccountSwitch(newAddress) {
    console.log("[Web3] Account switched to:", newAddress);

    try {
      this.provider = new ethers.BrowserProvider(window.ethereum);
      this.signer = await this.provider.getSigner();
      this.address = newAddress;
      const network = await this.provider.getNetwork();
      this.chainId = Number(network.chainId);

      this.pushEvent("account_switched", {
        address: this.address,
        chainId: this.chainId,
      });
    } catch (error) {
      console.error("[Web3] Error handling account switch:", error);
    }
  },
};
