// Explicit configuration avoids trusting an arbitrary Host header for canonical URLs.
export const origin = (process.env.RR10_PREVIEW_ORIGIN ?? 'https://t-03ha4qjtu4sa6czm16ws6kcxs-p22203.onamp.dev').replace(/\/$/, '');
export const canonical = (path: string) => `${origin}${path}`;
