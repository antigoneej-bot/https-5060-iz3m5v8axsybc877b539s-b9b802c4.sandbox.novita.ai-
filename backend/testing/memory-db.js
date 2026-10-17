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
  function field(entry, key) {
    if (key === '__name__') return entry[0].split('/').at(-1);
    return key.split('.').reduce((object, name) => object?.[name], entry[1]);
  }
  function compareValue(left, right) {
    if (left === right) return 0;
    if (left === null) return -1;
    if (right === null) return 1;
    // Timestamp ordering preserves nanosecond ties; toDate-only doubles remain supported.
    const time = value => Number.isInteger(value?.seconds) ? [value.seconds, value.nanoseconds] :
      value?.toDate ? [Math.floor(value.toDate().getTime() / 1000), value.toDate().getMilliseconds() * 1000000] : null;
    const a = time(left), b = time(right);
    if (a && b) return a[0] - b[0] || a[1] - b[1];
    return left < right ? -1 : left > right ? 1 : 0;
  }
  function collection(path, filters = [], limit = Infinity, order = [], group = false, after = null) {
    return {
      doc(id) {return doc(`${path}/${id ?? `generated-${++sequence}`}`);},
      where(key, op, value) {return collection(path, [...filters, {key, op, value}], limit, order, group, after);},
      limit(count) {return collection(path, filters, count, order, group, after);},
      orderBy(key, direction = 'asc') {return collection(path, filters, limit, [...order, {key, direction}], group, after);},
      startAfter(...values) {return collection(path, filters, limit, order, group, values);},
      async get() {
        let entries = [...rows].filter(([key, value]) => (group ? key.split('/').at(-2) === path : key.startsWith(path + '/') && !key.slice(path.length + 1).includes('/')) && filters.every(f => {
            const v = f.key.split('.').reduce((object, key) => object?.[key], value);
            return f.op === '==' ? v === f.value : f.op === '>' ? v > f.value : v >= f.value;
          }));
        // Firestore excludes documents missing any explicitly ordered field.
        entries = entries.filter(entry => order.every(item => field(entry, item.key) !== undefined));
        const compare = (left, rightValues) => {
          for (let index = 0; index < order.length; index++) {
            const item = order[index];
            const result = compareValue(field(left, item.key), rightValues[index]) * (item.direction === 'desc' ? -1 : 1);
            if (result) return result;
          }
          return 0;
        };
        if (order.length) entries.sort((a, b) => compare(a, order.map(item => field(b, item.key))));
        if (after) entries = entries.filter(entry => compare(entry, after) > 0);
        const docs = await Promise.all(entries.slice(0, limit).map(([key]) => doc(key).get()));
        return {docs, empty: docs.length === 0};
      },
    };
  }
  const db = {rows, deleted, doc, collection, collectionGroup: name => collection(name, [], Infinity, [], true), beforeCommit: null,
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
