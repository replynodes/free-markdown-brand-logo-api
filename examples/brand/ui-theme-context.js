export async function loadThemeContext(domain) {
  const response = await fetch(`https://brand.replynodes.com/${domain}`);
  if (!response.ok) throw new Error(`Brand lookup failed: ${response.status}`);
  const brand = await response.json();
  return {
    logo: brand.logo,
    colors: brand.colors,
    fonts: brand.fonts,
  };
}
