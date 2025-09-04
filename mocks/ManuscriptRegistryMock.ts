// mocks/ManuscriptRegistryMock.ts
import { Cl } from "@stacks/transactions";

type Manuscript = {
  owner: string;
  title: string;
  metadata: string;
  versions: string[];
  categories: string[];
  tags: string[];
  collaborators: Record<string, string[]>;
  revenueShares: Record<string, number>;
};

export class ManuscriptRegistryMock {
  private manuscripts: Map<string, Manuscript> = new Map();

  async registerManuscript(sender: string, hash: string, title: string, metadata: string) {
    if (!hash) return Cl.error(Cl.uint(3)); // invalid hash
    if (this.manuscripts.has(hash)) return Cl.error(Cl.uint(1)); // already exists

    this.manuscripts.set(hash, {
      owner: sender,
      title,
      metadata,
      versions: [],
      categories: [],
      tags: [],
      collaborators: {},
      revenueShares: {},
    });

    return Cl.ok(Cl.bool(true));
  }

  async getManuscriptDetails(hash: string) {
    return this.manuscripts.get(hash);
  }

  async transferOwnership(sender: string, hash: string, newOwner: string) {
    const manuscript = this.manuscripts.get(hash);
    if (!manuscript) return Cl.error(Cl.uint(4)); // not found
    if (manuscript.owner !== sender) return Cl.error(Cl.uint(2)); // not owner

    manuscript.owner = newOwner;
    return Cl.ok(Cl.bool(true));
  }

  async addVersion(sender: string, hash: string, newHash: string, version: number, notes: string) {
    const manuscript = this.manuscripts.get(hash);
    if (!manuscript) return Cl.error(Cl.uint(4));
    if (manuscript.owner !== sender) return Cl.error(Cl.uint(5)); // permission denied

    manuscript.versions.push(newHash);
    return Cl.ok(Cl.bool(true));
  }

  async addCategory(sender: string, hash: string, category: string, tags: string[]) {
    const manuscript = this.manuscripts.get(hash);
    if (!manuscript) return Cl.error(Cl.uint(4));
    if (manuscript.owner !== sender) return Cl.error(Cl.uint(5));
    if (tags.length > 10) return Cl.error(Cl.uint(5));

    manuscript.categories.push(category);
    manuscript.tags.push(...tags);
    return Cl.ok(Cl.bool(true));
  }

  async addCollaborator(sender: string, hash: string, collaborator: string, permissions: string[]) {
    const manuscript = this.manuscripts.get(hash);
    if (!manuscript) return Cl.error(Cl.uint(4));
    if (manuscript.owner !== sender) return Cl.error(Cl.uint(5));

    manuscript.collaborators[collaborator] = permissions;
    return Cl.ok(Cl.bool(true));
  }

  async hasPermission(hash: string, collaborator: string, permission: string) {
    const manuscript = this.manuscripts.get(hash);
    if (!manuscript) return Cl.error(Cl.uint(4));
    const perms = manuscript.collaborators[collaborator] || [];
    return Cl.ok(Cl.bool(perms.includes(permission)));
  }

  async setRevenueShare(sender: string, hash: string, account: string, percentage: number) {
    const manuscript = this.manuscripts.get(hash);
    if (!manuscript) return Cl.error(Cl.uint(4));
    if (manuscript.owner !== sender) return Cl.error(Cl.uint(5));

    const total = Object.values(manuscript.revenueShares).reduce((a, b) => a + b, 0) + percentage;
    if (total > 100) return Cl.error(Cl.uint(5));

    manuscript.revenueShares[account] = percentage;
    return Cl.ok(Cl.bool(true));
  }

  async verifyOwnership(hash: string, account: string) {
    const manuscript = this.manuscripts.get(hash);
    if (!manuscript) return Cl.error(Cl.uint(4));
    if (manuscript.owner !== account) return Cl.error(Cl.uint(5));
    return Cl.ok(Cl.bool(true));
  }
}
