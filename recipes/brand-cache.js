const cache = new Map();

export async function brandFor(domain) {
  if (cache.has(domain)) return cache.get(domain);
  const response = await fetch(`https://brand.replynodes.com/${domain}`);
  if (!response.ok) throw new Error(`Brand request failed: HTTP ${response.status}`);
  const brand = await response.json();
  cache.set(domain, brand); // Add an application TTL appropriate to your product.
  return brand; // Includes the live response shape, including `logos`.
}
