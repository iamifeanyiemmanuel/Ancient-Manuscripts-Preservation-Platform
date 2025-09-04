# 📜 Ancient Manuscripts Preservation Platform

Welcome to a revolutionary blockchain platform built on Stacks using Clarity smart contracts! This project addresses the real-world problem of preserving fragile ancient manuscripts by digitizing them, minting NFTs to represent ownership (e.g., for museums, collectors, or institutions), and ensuring controlled access for researchers. It prevents physical degradation while enabling global scholarly collaboration, verifying authenticity, and facilitating funding through royalties—all secured on the blockchain.

## ✨ Features
🔒 Digitize and register ancient manuscripts with immutable metadata  
🎟️ Mint NFTs for ownership, allowing transfer or sale while retaining digital access rights  
🔍 Controlled research access: Researchers can request and gain temporary or permanent viewing rights without owning the NFT  
📈 Authenticity verification: Prove the manuscript's origin and digitization history  
💰 Royalty system: Automatic royalties from NFT sales or access fees to fund preservation efforts  
🗳️ Governance for disputes: Community or expert voting on authenticity claims or access denials  
🚫 Anti-fraud measures: Prevent duplicate digitizations and ensure unique hashes  
🌍 Global accessibility: Store high-res metadata on-chain for easy querying  

## 🛠 How It Works
**For Manuscript Owners (e.g., Museums or Collectors)**  
- Upload a digitized version and generate a unique hash (e.g., SHA-256 of the content).  
- Call the `register-manuscript` function in the Manuscript Registry contract with the hash, title, description, and historical details.  
- Mint an NFT via the NFT Minting contract to claim ownership.  
- Set access policies in the Access Control contract (e.g., open to verified researchers or fee-based).  

**For Researchers**  
- Search for manuscripts using the Metadata Storage contract.  
- Submit a request via the Research Request contract, providing credentials or reasons.  
- Upon approval (manual or automated), gain access through a temporary token or view key.  
- Verify authenticity using the Verification contract to check timestamps and ownership history.  

**For Buyers/Collectors**  
- Browse and purchase NFTs on the integrated Marketplace contract.  
- Royalties from sales automatically flow to the original digitizer or preservation fund via the Royalty contract.  
- Use the Escrow contract for secure transfers during sales.  

**For Governance Participants**  
- In case of disputes (e.g., contested ownership), propose votes in the Governance contract.  
- Experts or token holders vote to resolve issues, ensuring decentralized decision-making.  

This setup solves preservation challenges by reducing physical handling of artifacts, democratizing access for education and research, and creating economic incentives for digitization—all while maintaining security and provenance on the Stacks blockchain.

## 📑 Smart Contracts
The platform is powered by 8 Clarity smart contracts, each handling a specific aspect for modularity and security:  

1. **Manuscript Registry**: Handles registration of digitized manuscripts, storing unique hashes, titles, descriptions, and timestamps to prevent duplicates.  
2. **NFT Minting**: Mints non-fungible tokens representing ownership of the digitized manuscript, linked to the registry.  
3. **Access Control**: Manages permissions for viewing digital content, including role-based access (e.g., owner, researcher) and time-limited tokens.  
4. **Research Request**: Processes access requests from researchers, including verification of credentials and approval workflows.  
5. **Metadata Storage**: Stores and queries detailed metadata (e.g., historical context, images hashes) in an immutable on-chain database.  
6. **Verification**: Provides functions to verify ownership, authenticity, and digitization history against blockchain records.  
7. **Royalty**: Automates distribution of royalties from NFT sales or access fees to fund ongoing preservation.  
8. **Marketplace**: Facilitates buying, selling, and transferring NFTs with built-in escrow for secure trades.  

These contracts interact seamlessly (e.g., NFT Minting calls Registry for validation), ensuring a robust, scalable system. Deploy them on Stacks for Bitcoin-secured transactions!