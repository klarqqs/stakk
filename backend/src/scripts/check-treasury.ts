import stellarService from '../services/stellar.service.ts';

const treasuryPublicKey = process.env.TREASURY_PUBLIC_KEY;

async function main() {
  if (!treasuryPublicKey) {
    console.error('Set TREASURY_PUBLIC_KEY in .env (derive from TREASURY_SECRET_KEY)');
    process.exit(1);
  }

  try {
    const balances = await stellarService.getBalance(treasuryPublicKey, 1, false);

    console.log('\n🏦 Treasury Status\n');
    if (balances.length === 0) {
      console.log('  No balances (account may not exist yet)');
    } else {
      for (const b of balances as { asset_type: string; balance: string }[]) {
        const name = b.asset_type === 'native' ? 'XLM' : b.asset_type;
        console.log(`  ${name}: ${b.balance}`);
      }

      const xlm = balances.find((b: { asset_type: string }) => b.asset_type === 'native') as { balance: string } | undefined;
      if (xlm && parseFloat(xlm.balance) < 5) {
        console.log('\n⚠️  WARNING: XLM running low! Top up to fund new user accounts.');
      }
    }
    console.log('');
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main();
