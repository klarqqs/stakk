import flutterwaveService from './services/flutterwave.service.ts';

async function testFlutterwave() {
  try {
    console.log('🧪 Testing Flutterwave virtual account creation...\n');
    
    const result = await flutterwaveService.createVirtualAccount(
      2,
      'test@example.com',
      '+2348012345678',
      'Test User',
      { bvn: '22390920296' }  // Static account - requires BVN
    );
    
    console.log('✅ Virtual account created successfully!');
    console.log('Account Number:', result.account_number);
    console.log('Account Name:', result.account_name);
    console.log('Bank:', result.bank_name);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

testFlutterwave();