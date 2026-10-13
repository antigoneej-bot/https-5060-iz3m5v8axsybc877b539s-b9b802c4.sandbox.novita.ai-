// Deterministic Firestore double: atomic staged commits, serialized transactions
// and read-before-write enforcement. This does not emulate network/IAM/indexes.
export function memoryDb(initial = {}) {
  const rows = new Map(Object.entries(initial));
  let sequence = 0;
  let tail = Promise.resolve();
  const deleted = Symbol('deleted-field');
  function write(path, value, merge = false) {
    const next = merge ? {...rows.get(path), ...value} : {...value};
    for (const key of Object.keys(next)) if (next[key] === deleted) delete next[key];
    rows.set(path, next);
  }
  function doc(path) {
    return {path, id: path.split('/').at(-1),
      async get() { const data = rows.get(path); return {
        id: this.id, ref: this, exists: rows.has(path), data: () => data}; },
      async set(value, options) {write(path, value, options?.merge);},
      async update(value) {if (!rows.has(path)) throw new Error('not-found'); write(path, value, true);},
      async delete() {rows.delete(path);},
    };
  }
  function collection(path, filters = [], limit = Infinity, order = null) {
    return {
      doc(id) {return doc(`${path}/${id ?? `generated-${++sequence}`}`);},
      where(key, op, value) {return collection(path, [...filters, {key, op, value}], limit, order);},
      limit(count) {return collection(path, filters, count, order);},
      orderBy(key, direction = 'asc') {return collection(path, filters, limit, {key, direction});},
      async get() {
        let entries = [...rows].filter(([key, value]) => key.startsWith(path + '/') &&
          !key.slice(path.length + 1).includes('/') && filters.every(f => {
            const v = f.key.split('.').reduce((object, key) => object?.[key], value);
            return f.op === '==' ? v === f.value : f.op === '>' ? v > f.value : v >= f.value;
          }));
        if (order) entries.sort((a, b) => {
          const x = a[1][order.key], y = b[1][order.key];
          return (x < y ? -1 : x > y ? 1 : 0) * (order.direction === 'desc' ? -1 : 1);
        });
        const docs = await Promise.all(entries.slice(0, limit).map(([key]) => doc(key).get()));
        return {docs, empty: docs.length === 0};
      },
    };
  }
  const db = {rows, deleted, doc, collection, beforeCommit: null,
    runTransaction(fn) {
      const operation = tail.then(async () => {
        const writes = [];
        const result = await fn({
          get: ref => {if (writes.length) throw new Error('read-after-write'); return ref.get();},
          set: (ref, data, options) => writes.push(() => write(ref.path, data, options?.merge)),
          update: (ref, data) => {if (!rows.has(ref.path)) throw new Error('not-found'); writes.push(() => write(ref.path, data, true));},
          delete: ref => writes.push(() => rows.delete(ref.path)),
        });
        if (db.beforeCommit) await db.beforeCommit();
        for (const write of writes) write();
        return result;
      });
      tail = operation.catch(() => {});
      return operation;
    },
    async recursiveDelete(ref) {
      for (const key of rows.keys()) if (key === ref.path || key.startsWith(ref.path + '/')) rows.delete(key);
    },
  };
  return db;
}
