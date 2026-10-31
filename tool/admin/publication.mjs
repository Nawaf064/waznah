// Pure publication boundary, also exercised with an in-memory transaction in tests.
export async function publishCatalog(db, data) {
  const ref = db.doc('catalog/published');
  await db.runTransaction(async tx => {
    const current = await tx.get(ref);
    const previous = current.exists ? current.data() : null;
    const revision = previous?.revision ?? 0;
    if (!Number.isSafeInteger(data.revision) || data.revision !== revision + 1) {
      throw new Error('Revision conflict; read current catalog before publishing');
    }
    if (!Array.isArray(data.partIds) || data.partIds.length === 0) {
      throw new Error('Refusing an empty catalog');
    }
    if (previous && (!Array.isArray(previous.partIds) ||
        previous.partIds.some(id => !data.partIds.includes(id)))) {
      throw new Error('Keep existing part IDs to preserve customer favorites and maintenance lists');
    }
    if (previous) {
      // The history write and the active revision succeed or fail together.
      tx.create(db.doc(`catalog_history/revision-${revision}`), previous);
    }
    tx.set(ref, data);
  });
}
