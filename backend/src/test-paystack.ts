import paystackService from './services/paystack.service.ts';

async function testPaystack() {
  try {
    console.log('🧪 Testing Paystack virtual account creation...\n');
    
    const result = await paystackService.createVirtualAccount(
      2, 
      '+2348012345678', 
      'test@example.com'
    );

    console.log('✅ Virtual account created successfully!');
    if (
      typeof result === 'object' &&
      result !== null &&
      'account_number' in result &&
      'account_name' in result &&
      'bank' in result &&
      typeof (result as {[key: string]: any}).bank === 'object' &&
      (result as {[key: string]: any}).bank !== null &&
      'name' in (result as {[key: string]: any}).bank
    ) {
      console.log('Account Number:', (result as any).account_number);
      console.log('Account Name:', (result as any).account_name);
      console.log('Bank:', (result as any).bank.name);
    } else {
      console.error('❌ Result does not have the expected structure:', result);
      process.exit(1);
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

testPaystack();