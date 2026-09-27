import Image from "next/image";

export function CompanyLogo({ domain }: { domain: string }) {
  const src = `https://img.replynodes.com/${domain}`;
  return <Image src={src} alt={`${domain} logo`} width={40} height={40} />;
}

// Next.js still needs this remote host allowed in next.config.js.
// The endpoint can return a placeholder image; use a local fallback for hard failures.
