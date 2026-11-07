// Preserve source order and bound DB pressure; reject the whole read on failure.
export async function boundedMap(items, concurrency, read) {
  if (!Number.isInteger(concurrency) || concurrency < 1) throw new Error('invalid-concurrency');
  const results = new Array(items.length);
  let next = 0;
  await Promise.all(Array.from({length: Math.min(concurrency, items.length)}, async () => {
    while (next < items.length) {
      const index = next++;
      results[index] = await read(items[index], index);
    }
  }));
  return results;
}
