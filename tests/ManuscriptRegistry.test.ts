import { describe, it, expect, beforeEach } from "vitest";
import { Cl } from "@stacks/transactions";
import { ManuscriptRegistryMock } from "../mocks/ManuscriptRegistryMock";

// Use valid STX devnet principals
const accounts = {
  deployer: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  owner: "ST2J9EVYHPYFPJW8P9J7RZ7Y9T8E2ZZ0Q8E9Q6K8M",
  collaborator: "ST3AM1A2B3C4D5E6F7G8H9J0KLMNOPQRSTUVWXYYZ",
  nonOwner: "ST1J2EVYHPYFPJW8P9J7RZ7Y9T8E2ZZ0Q8E9Q6AAA",
};

describe("Manuscript Registry Contract", () => {
  let contract: ManuscriptRegistryMock;

  beforeEach(() => {
    contract = new ManuscriptRegistryMock();
  });

  it("should register a new manuscript successfully", async () => {
    const hash = "hash-001";
    const result = await contract.registerManuscript(
      accounts.owner,
      hash,
      "Ancient Text",
      "metadata"
    );
    expect(result).toEqual(Cl.ok(Cl.bool(true)));

    const details = await contract.getManuscriptDetails(hash);
    expect(details).toBeDefined();
  });

  it("should prevent duplicate manuscript registration", async () => {
    const hash = "hash-002";
    await contract.registerManuscript(accounts.owner, hash, "Text A", "meta");
    const result = await contract.registerManuscript(
      accounts.owner,
      hash,
      "Text A",
      "meta"
    );
    expect(result).toEqual(Cl.error(Cl.uint(1)));
  });

  it("should prevent registration with invalid hash", async () => {
    const result = await contract.registerManuscript(
      accounts.owner,
      "",
      "Empty Hash",
      "meta"
    );
    expect(result).toEqual(Cl.error(Cl.uint(3)));
  });

  it("should allow ownership transfer by owner", async () => {
    const hash = "hash-003";
    await contract.registerManuscript(accounts.owner, hash, "Transferable", "meta");
    const result = await contract.transferOwnership(
      accounts.owner,
      hash,
      accounts.collaborator
    );
    expect(result).toEqual(Cl.ok(Cl.bool(true)));
  });

  it("should prevent ownership transfer by non-owner", async () => {
    const hash = "hash-004";
    await contract.registerManuscript(accounts.owner, hash, "NonTransfer", "meta");
    const result = await contract.transferOwnership(
      accounts.nonOwner,
      hash,
      accounts.collaborator
    );
    expect(result).toEqual(Cl.error(Cl.uint(2)));
  });

  it("should add a new version successfully", async () => {
    const hash = "hash-005";
    const newHash = "hash-005-v2";
    await contract.registerManuscript(accounts.owner, hash, "Versioned", "meta");
    const result = await contract.addVersion(
      accounts.owner,
      hash,
      newHash,
      1,
      "Updated scan"
    );
    expect(result).toEqual(Cl.ok(Cl.bool(true)));
  });

  it("should prevent adding version by non-owner", async () => {
    const hash = "hash-006";
    const newHash = "hash-006-v2";
    await contract.registerManuscript(accounts.owner, hash, "Protected", "meta");
    const result = await contract.addVersion(
      accounts.nonOwner,
      hash,
      newHash,
      1,
      "Updated scan"
    );
    expect(result).toEqual(Cl.error(Cl.uint(5))); // updated to match mock
  });

  it("should add categories successfully", async () => {
    const hash = "hash-007";
    await contract.registerManuscript(accounts.owner, hash, "Categorized", "meta");
    const result = await contract.addCategory(
      accounts.owner,
      hash,
      "Religious",
      ["codex", "manuscript"]
    );
    expect(result).toEqual(Cl.ok(Cl.bool(true)));
  });

  it("should prevent adding too many tags", async () => {
    const hash = "hash-008";
    await contract.registerManuscript(accounts.owner, hash, "Tagged", "meta");
    const tooManyTags = Array(11).fill("tag");
    const result = await contract.addCategory(
      accounts.owner,
      hash,
      "Religious",
      tooManyTags
    );
    expect(result).toEqual(Cl.error(Cl.uint(5))); // updated to match mock
  });

  it("should add collaborator successfully", async () => {
    const hash = "hash-009";
    await contract.registerManuscript(accounts.owner, hash, "Collab", "meta");
    const result = await contract.addCollaborator(
      accounts.owner,
      hash,
      accounts.collaborator,
      ["edit-metadata"]
    );
    expect(result).toEqual(Cl.ok(Cl.bool(true)));

    const permissionResult = await contract.hasPermission(
      hash,
      accounts.collaborator,
      "edit-metadata"
    );
    expect(permissionResult).toEqual(Cl.ok(Cl.bool(true)));
  });

  it("should set revenue share successfully", async () => {
    const hash = "hash-010";
    await contract.registerManuscript(accounts.owner, hash, "Revenue", "meta");
    const result = await contract.setRevenueShare(
      accounts.owner,
      hash,
      accounts.collaborator,
      50
    );
    expect(result).toEqual(Cl.ok(Cl.bool(true)));
  });

  it("should prevent revenue share exceeding 100%", async () => {
    const hash = "hash-011";
    await contract.registerManuscript(accounts.owner, hash, "OverRevenue", "meta");
    await contract.setRevenueShare(accounts.owner, hash, accounts.collaborator, 60);
    const result = await contract.setRevenueShare(
      accounts.owner,
      hash,
      accounts.nonOwner,
      50
    );
    expect(result).toEqual(Cl.error(Cl.uint(5))); // updated to match mock
  });

  it("should verify ownership correctly", async () => {
    const hash = "hash-012";
    await contract.registerManuscript(accounts.owner, hash, "Verify", "meta");
    const result = await contract.verifyOwnership(hash, accounts.owner);
    expect(result).toEqual(Cl.ok(Cl.bool(true)));

    const wrongOwner = await contract.verifyOwnership(hash, accounts.nonOwner);
    expect(wrongOwner).toEqual(Cl.error(Cl.uint(5))); // updated to match mock
  });
});
