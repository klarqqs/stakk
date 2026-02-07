/** Production deposit limits (NGN) */
export const DEPOSIT_LIMITS = {
  /** Max per single deposit */
  MAX_PER_DEPOSIT: Number(process.env.MAX_DEPOSIT_NGN) || 500_000,
  /** Max total deposits per user */
  MAX_PER_USER: Number(process.env.MAX_DEPOSIT_PER_USER_NGN) || 2_000_000,
  /** Platform-wide daily limit (optional) */
  MAX_DAILY_PLATFORM: Number(process.env.MAX_DAILY_DEPOSITS_NGN) || 10_000_000,
};

/** NGN to USD rate - update via env or fetch from API in production */
export const NGN_USD_RATE = Number(process.env.NGN_USD_RATE) || 1580;

/** Service fee (0-1). 0.015 = 1.5% */
export const DEPOSIT_FEE_RATE = Number(process.env.DEPOSIT_FEE_RATE) || 0.015;
